/// Messages of the SSH agent protocol (draft-miller-ssh-agent) that log
/// in with the agent's keys: list the identities, sign a challenge.
library;

import 'dart:convert';
import 'dart:typed_data';

/// `SSH_AGENTC_REQUEST_IDENTITIES`.
const agentRequestIdentities = 11;

/// `SSH_AGENT_IDENTITIES_ANSWER`.
const agentIdentitiesAnswer = 12;

/// `SSH_AGENTC_SIGN_REQUEST`.
const agentSignRequest = 13;

/// `SSH_AGENT_SIGN_RESPONSE`.
const agentSignResponse = 14;

/// `SSH_AGENT_RSA_SHA2_256`: sign an `ssh-rsa` key with `rsa-sha2-256`.
const agentRsaSha2_256 = 2;

/// A key the agent holds: its public key blob in SSH wire format and its
/// comment.
typedef AgentIdentity = ({Uint8List blob, String comment});

/// [payload] framed as an agent message: a 4-byte big-endian length, then
/// the payload.
Uint8List frameAgentMessage(Uint8List payload) =>
    (BytesBuilder()
          ..add(_uint32(payload.length))
          ..add(payload))
        .toBytes();

/// The payload of the first whole message framed in [buffer] and the
/// number of bytes it took, or null when [buffer] holds no whole message.
(Uint8List, int)? readAgentFrame(Uint8List buffer) {
  if (buffer.length < 4) return null;
  final length = ByteData.sublistView(buffer).getUint32(0);
  if (buffer.length < 4 + length) return null;
  return (Uint8List.sublistView(buffer, 4, 4 + length), 4 + length);
}

/// The request for the agent's identities (unframed).
Uint8List requestIdentitiesMessage() =>
    Uint8List.fromList([agentRequestIdentities]);

/// The identities in an identities answer [payload]. Throws a
/// [FormatException] for any other message.
List<AgentIdentity> parseIdentitiesAnswer(Uint8List payload) {
  final reader = _Reader(payload);
  final type = reader.byte();
  if (type != agentIdentitiesAnswer) {
    throw FormatException('expected an identities answer, got $type');
  }
  final count = reader.uint32();
  return [
    for (var i = 0; i < count; i++)
      (blob: reader.string(), comment: utf8.decode(reader.string())),
  ];
}

/// The request to sign [data] with the key [blob] (unframed), using
/// [flags] such as [agentRsaSha2_256].
Uint8List signRequestMessage(Uint8List blob, Uint8List data, int flags) =>
    (BytesBuilder()
          ..addByte(agentSignRequest)
          ..add(_string(blob))
          ..add(_string(data))
          ..add(_uint32(flags)))
        .toBytes();

/// The signature (SSH wire format) in a sign response [payload]. Throws a
/// [FormatException] for any other message, such as the agent's refusal.
Uint8List parseSignResponse(Uint8List payload) {
  final reader = _Reader(payload);
  final type = reader.byte();
  if (type != agentSignResponse) {
    throw FormatException('the SSH agent refused to sign (message $type)');
  }
  return reader.string();
}

/// The key type named at the start of a public key [blob], such as
/// `ssh-ed25519`.
String agentKeyType(Uint8List blob) => utf8.decode(_Reader(blob).string());

/// The signature algorithm and agent flags to log in with a key of
/// [keyType]: RSA keys sign with `rsa-sha2-256` (RFC 8332), others with
/// their own algorithm.
(String, int) agentSignatureAlgorithm(String keyType) =>
    keyType == 'ssh-rsa' ? ('rsa-sha2-256', agentRsaSha2_256) : (keyType, 0);

Uint8List _uint32(int value) =>
    (ByteData(4)..setUint32(0, value)).buffer.asUint8List();

Uint8List _string(Uint8List bytes) =>
    (BytesBuilder()
          ..add(_uint32(bytes.length))
          ..add(bytes))
        .toBytes();

/// Reads SSH wire types from [_bytes].
class _Reader {
  _Reader(this._bytes);

  final Uint8List _bytes;
  var _offset = 0;

  int byte() {
    _need(1);
    return _bytes[_offset++];
  }

  int uint32() {
    _need(4);
    final value = ByteData.sublistView(_bytes).getUint32(_offset);
    _offset += 4;
    return value;
  }

  Uint8List string() {
    final length = uint32();
    _need(length);
    final value = Uint8List.sublistView(_bytes, _offset, _offset + length);
    _offset += length;
    return value;
  }

  void _need(int count) {
    if (_offset + count > _bytes.length) {
      throw const FormatException('truncated SSH agent message');
    }
  }
}
