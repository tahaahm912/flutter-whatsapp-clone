package keys

import (
	"crypto/rand"
	"encoding/base64"
	"testing"
)

// randomBase64 generates n random bytes and returns their standard
// base64 encoding — used to build realistic-length test fixtures
// without hand-constructing (and possibly miscounting) base64 strings.
func randomBase64(t *testing.T, n int) string {
	t.Helper()
	buf := make([]byte, n)
	if _, err := rand.Read(buf); err != nil {
		t.Fatalf("failed to generate random bytes: %v", err)
	}
	return base64.StdEncoding.EncodeToString(buf)
}

func TestUploadKeysRequest_Validate(t *testing.T) {
	validIdentityKey32 := randomBase64(t, 32)
	validIdentityKey33 := randomBase64(t, 33)
	validSignature := randomBase64(t, 64)

	tests := []struct {
		name    string
		req     UploadKeysRequest
		wantErr bool
	}{
		{
			name: "valid: 32-byte raw identity key, no optional fields",
			req: UploadKeysRequest{
				IdentityPublicKey: validIdentityKey32,
				RegistrationID:    12345,
			},
			wantErr: false,
		},
		{
			name: "valid: 33-byte type-prefixed identity key",
			req: UploadKeysRequest{
				IdentityPublicKey: validIdentityKey33,
				RegistrationID:    1,
			},
			wantErr: false,
		},
		{
			name: "invalid: identity key is not base64 at all",
			req: UploadKeysRequest{
				IdentityPublicKey: "not valid base64!!! ###",
				RegistrationID:    12345,
			},
			wantErr: true,
		},
		{
			name: "invalid: identity key decodes but wrong length (16 bytes)",
			req: UploadKeysRequest{
				IdentityPublicKey: randomBase64(t, 16),
				RegistrationID:    12345,
			},
			wantErr: true,
		},
		{
			name: "invalid: registration_id is zero",
			req: UploadKeysRequest{
				IdentityPublicKey: validIdentityKey32,
				RegistrationID:    0,
			},
			wantErr: true,
		},
		{
			name: "invalid: registration_id exceeds the 14-bit max",
			req: UploadKeysRequest{
				IdentityPublicKey: validIdentityKey32,
				RegistrationID:    99999,
			},
			wantErr: true,
		},
		{
			name: "invalid: registration_id negative",
			req: UploadKeysRequest{
				IdentityPublicKey: validIdentityKey32,
				RegistrationID:    -1,
			},
			wantErr: true,
		},
		{
			name: "valid: signed_prekey with key_id = 0 (regression test — see dto.go comment)",
			req: UploadKeysRequest{
				IdentityPublicKey: validIdentityKey32,
				RegistrationID:    1,
				SignedPrekey: &SignedPrekeyInput{
					KeyID:     0,
					PublicKey: validIdentityKey32,
					Signature: validSignature,
				},
			},
			wantErr: false,
		},
		{
			name: "invalid: signed_prekey.key_id negative",
			req: UploadKeysRequest{
				IdentityPublicKey: validIdentityKey32,
				RegistrationID:    1,
				SignedPrekey: &SignedPrekeyInput{
					KeyID:     -1,
					PublicKey: validIdentityKey32,
					Signature: validSignature,
				},
			},
			wantErr: true,
		},
		{
			name: "invalid: signed_prekey.signature wrong length",
			req: UploadKeysRequest{
				IdentityPublicKey: validIdentityKey32,
				RegistrationID:    1,
				SignedPrekey: &SignedPrekeyInput{
					KeyID:     1,
					PublicKey: validIdentityKey32,
					Signature: randomBase64(t, 10), // too short for a real signature
				},
			},
			wantErr: true,
		},
		{
			name: "valid: full bundle with one-time prekeys, one with key_id = 0",
			req: UploadKeysRequest{
				IdentityPublicKey: validIdentityKey32,
				RegistrationID:    1,
				SignedPrekey: &SignedPrekeyInput{
					KeyID:     1,
					PublicKey: validIdentityKey33,
					Signature: validSignature,
				},
				OneTimePrekeys: []OneTimePrekeyInput{
					{KeyID: 0, PublicKey: validIdentityKey32},
					{KeyID: 1, PublicKey: validIdentityKey33},
				},
			},
			wantErr: false,
		},
		{
			name: "invalid: second one-time prekey has a bad key (error should still be caught, not just the first)",
			req: UploadKeysRequest{
				IdentityPublicKey: validIdentityKey32,
				RegistrationID:    1,
				OneTimePrekeys: []OneTimePrekeyInput{
					{KeyID: 0, PublicKey: validIdentityKey32},
					{KeyID: 1, PublicKey: "garbage-not-a-key"},
				},
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.req.Validate()
			if tt.wantErr && err == nil {
				t.Fatalf("expected an error, got nil")
			}
			if !tt.wantErr && err != nil {
				t.Fatalf("expected no error, got: %v", err)
			}
		})
	}
}
