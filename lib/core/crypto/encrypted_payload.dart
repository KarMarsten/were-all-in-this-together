import 'dart:typed_data';

/// A sealed envelope of ciphertext plus the metadata needed to open it.
///
/// We persist and (eventually) sync encrypted row payloads as single opaque
/// byte strings. Callers should never need to reason about the individual
/// fields — they read/write via `toBytes` and `EncryptedPayload.fromBytes`.
///
/// Wire format:
///
/// ```text
///   +---------+----------------+----------------+-----------------+
///   | version | nonce (24B)    | mac (16B)      | ciphertext (..) |
///   +---------+----------------+----------------+-----------------+
///       1B          24B              16B            plaintext len
/// ```
///
/// A leading version byte is part of the format so we can migrate the
/// envelope (for example, rotate AEAD primitives) without touching every
/// stored payload at once.
class EncryptedPayload {
  const EncryptedPayload({
    required this.version,
    required this.nonce,
    required this.mac,
    required this.ciphertext,
  });

  /// Parse a byte string produced by [toBytes]. Throws if the input is too
  /// short, malformed, or carries an unsupported version — callers should
  /// treat these as *unopenable* payloads rather than data loss; they usually
  /// indicate an older or newer app version than the one that wrote the row.
  factory EncryptedPayload.fromBytes(Uint8List input) {
    if (input.length < headerLength) {
      throw ArgumentError(
        'EncryptedPayload bytes too short: got ${input.length}, '
        'need at least $headerLength',
      );
    }
    final version = input[0];
    if (version != currentVersion) {
      throw UnsupportedError(
        'Unsupported EncryptedPayload version: $version '
        '(this build writes v$currentVersion)',
      );
    }
    return EncryptedPayload(
      version: version,
      nonce: Uint8List.sublistView(input, 1, 1 + nonceLength),
      mac: Uint8List.sublistView(input, 1 + nonceLength, headerLength),
      ciphertext: Uint8List.sublistView(input, headerLength),
    );
  }

  /// The only version emitted today. XChaCha20-Poly1305, 24-byte nonce,
  /// 16-byte Poly1305 tag.
  static const int currentVersion = 1;

  /// XChaCha20 uses a 192-bit (24-byte) nonce. Random nonces are safe here
  /// because the collision risk over a practical number of messages is
  /// negligible.
  static const int nonceLength = 24;

  /// Poly1305 produces a 16-byte authentication tag.
  static const int macLength = 16;

  /// Minimum byte length of a serialised payload (header + tag; empty
  /// ciphertext is valid).
  static const int headerLength = 1 + nonceLength + macLength;

  final int version;
  final Uint8List nonce;
  final Uint8List mac;
  final Uint8List ciphertext;

  /// Serialise to a single byte string for storage or transport.
  Uint8List toBytes() {
    final out = BytesBuilder(copy: false)
      ..addByte(version)
      ..add(nonce)
      ..add(mac)
      ..add(ciphertext);
    return out.toBytes();
  }
}
