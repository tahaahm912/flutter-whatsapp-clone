package keys

import (
	"encoding/base64"
	"fmt"
)

// Expected byte lengths for Signal Protocol Curve25519 key material.
// Two lengths are accepted for public keys because different Signal
// library implementations serialize them differently: some emit the
// raw 32-byte Curve25519 point, others prefix it with Signal's 1-byte
// key-type indicator (0x05) for a 33-byte total. Rather than guessing
// which convention Flutter's libsignal package uses and being wrong,
// both are accepted — the actual cryptographic content is identical
// either way, this is purely a serialization detail.
const (
	rawPublicKeyLen       = 32
	prefixedPublicKeyLen  = 33
	xeddsaSignatureLen    = 64
	minRegistrationID     = 1
	maxRegistrationID     = 16380 // Signal's registration ID is a 14-bit value
	maxKeyID              = 0xFFFFFF
)

// Validate checks the actual key material's format and length —
// beyond what Gin's binding tags can express (non-empty, non-negative
// etc.), this confirms each key is valid base64 that decodes to a
// plausible Curve25519 key/signature length. Called explicitly by the
// handler after ShouldBindJSON succeeds.
func (r UploadKeysRequest) Validate() error {
	if err := validatePublicKey(r.IdentityPublicKey, "identity_public_key"); err != nil {
		return err
	}
	if r.RegistrationID < minRegistrationID || r.RegistrationID > maxRegistrationID {
		return fmt.Errorf("registration_id must be between %d and %d", minRegistrationID, maxRegistrationID)
	}

	if r.SignedPrekey != nil {
		if r.SignedPrekey.KeyID < 0 || r.SignedPrekey.KeyID > maxKeyID {
			return fmt.Errorf("signed_prekey.key_id must be between 0 and %d", maxKeyID)
		}
		if err := validatePublicKey(r.SignedPrekey.PublicKey, "signed_prekey.public_key"); err != nil {
			return err
		}
		if err := validateSignature(r.SignedPrekey.Signature); err != nil {
			return err
		}
	}

	for i, otpk := range r.OneTimePrekeys {
		if otpk.KeyID < 0 || otpk.KeyID > maxKeyID {
			return fmt.Errorf("one_time_prekeys[%d].key_id must be between 0 and %d", i, maxKeyID)
		}
		if err := validatePublicKey(otpk.PublicKey, fmt.Sprintf("one_time_prekeys[%d].public_key", i)); err != nil {
			return err
		}
	}

	return nil
}

// decodeBase64Flexible tries every common base64 variant before
// giving up. Real-world Signal library bindings aren't fully
// consistent about padded vs. unpadded, or standard vs. URL-safe,
// base64 — being strict about exactly one variant risks rejecting
// perfectly valid keys from a client using a different (still
// correct) encoding. This is deliberately permissive on *encoding
// style*; it is not permissive on the actual decoded byte length,
// which is checked separately and strictly.
func decodeBase64Flexible(s string) ([]byte, error) {
	if decoded, err := base64.StdEncoding.DecodeString(s); err == nil {
		return decoded, nil
	}
	if decoded, err := base64.RawStdEncoding.DecodeString(s); err == nil {
		return decoded, nil
	}
	if decoded, err := base64.URLEncoding.DecodeString(s); err == nil {
		return decoded, nil
	}
	if decoded, err := base64.RawURLEncoding.DecodeString(s); err == nil {
		return decoded, nil
	}
	return nil, fmt.Errorf("not valid base64 (tried standard, raw-standard, URL-safe, and raw-URL-safe variants)")
}

func validatePublicKey(value, fieldName string) error {
	decoded, err := decodeBase64Flexible(value)
	if err != nil {
		return fmt.Errorf("%s: %w", fieldName, err)
	}
	if len(decoded) != rawPublicKeyLen && len(decoded) != prefixedPublicKeyLen {
		return fmt.Errorf(
			"%s must decode to %d or %d bytes (a Curve25519 public key, with or without Signal's type-byte prefix), got %d bytes",
			fieldName, rawPublicKeyLen, prefixedPublicKeyLen, len(decoded),
		)
	}
	return nil
}

func validateSignature(value string) error {
	decoded, err := decodeBase64Flexible(value)
	if err != nil {
		return fmt.Errorf("signed_prekey.signature: %w", err)
	}
	if len(decoded) != xeddsaSignatureLen {
		return fmt.Errorf("signed_prekey.signature must decode to %d bytes (an XEdDSA signature), got %d bytes", xeddsaSignatureLen, len(decoded))
	}
	return nil
}
