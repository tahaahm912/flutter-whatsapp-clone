package keys

// UploadKeysRequest is the body for POST /users/keys.
//
// Only IdentityPublicKey/RegistrationID are required — SignedPrekey
// and OneTimePrekeys are optional, deliberately, because of how the
// two Flutter days that need this endpoint are sequenced: Day 3 only
// generates an Identity Key Pair locally; the signed prekey and
// one-time prekey batch aren't generated until Day 4. This single
// endpoint supports calling it once today with just the identity key,
// then again tomorrow (or any time after) to add the rest — no second
// endpoint needed, and no artificial requirement to have everything
// ready before uploading anything.
type UploadKeysRequest struct {
	IdentityPublicKey string               `json:"identity_public_key" binding:"required"`
	RegistrationID    int                  `json:"registration_id" binding:"required"`
	SignedPrekey      *SignedPrekeyInput   `json:"signed_prekey,omitempty"`
	OneTimePrekeys    []OneTimePrekeyInput `json:"one_time_prekeys,omitempty"`
}

// SignedPrekeyInput is one signed pre-key to store (or rotate to).
//
// KeyID uses `gte=0`, not `required` — "required" on an int rejects
// the zero value, but key_id=0 is a legitimate, valid prekey ID in
// the Signal Protocol (IDs commonly start at 0). Using `required`
// here was a latent bug: any client whose very first prekey happened
// to be ID 0 would have had it silently rejected as "missing."
type SignedPrekeyInput struct {
	KeyID     int    `json:"key_id" binding:"gte=0"`
	PublicKey string `json:"public_key" binding:"required"`
	Signature string `json:"signature" binding:"required"`
}

// OneTimePrekeyInput is one one-time pre-key in a batch upload.
// See SignedPrekeyInput's KeyID comment — same reasoning applies.
type OneTimePrekeyInput struct {
	KeyID     int    `json:"key_id" binding:"gte=0"`
	PublicKey string `json:"public_key" binding:"required"`
}

// UploadKeysResponse reports what was actually stored — useful for a
// client that calls this endpoint incrementally across two days (or
// re-uploads a fresh one-time prekey batch when running low) to
// confirm each piece landed.
type UploadKeysResponse struct {
	IdentityKeyStored    bool `json:"identity_key_stored"`
	SignedPrekeyStored   bool `json:"signed_prekey_stored"`
	OneTimePrekeysStored int  `json:"one_time_prekeys_stored"`
}

// KeyBundleResponse is what GET /users/:userId/keys returns — a
// PreKeyBundle per active device (a user can have more than one
// device; a real Signal-protocol client must establish a separate
// encrypted session with EACH of the recipient's devices to reach
// them everywhere they're logged in).
type KeyBundleResponse struct {
	UserID  string            `json:"user_id"`
	Devices []DeviceKeyBundle `json:"devices"`
}

// DeviceKeyBundle is everything needed to start an X3DH session with
// one specific device.
type DeviceKeyBundle struct {
	DeviceID     string              `json:"device_id"`
	IdentityKey  IdentityKeyOutput   `json:"identity_key"`
	SignedPrekey SignedPrekeyOutput  `json:"signed_prekey"`
	// OneTimePrekey is a pointer WITHOUT omitempty on purpose: if the
	// device has run out of one-time pre-keys, the field should still
	// appear as an explicit `null`, not be silently absent from the
	// JSON — the client needs to be able to tell "no one-time key was
	// available" apart from "the server forgot to include this field".
	OneTimePrekey *OneTimePrekeyOutput `json:"one_time_prekey"`
}

// IdentityKeyOutput is the public half of a device's long-term
// identity key pair.
type IdentityKeyOutput struct {
	PublicKey      string `json:"public_key"`
	RegistrationID int    `json:"registration_id"`
}

// SignedPrekeyOutput is a device's current active signed pre-key.
type SignedPrekeyOutput struct {
	KeyID     int    `json:"key_id"`
	PublicKey string `json:"public_key"`
	Signature string `json:"signature"`
}

// OneTimePrekeyOutput is a single one-time pre-key, claimed and
// consumed as part of serving this response — see Service.claimOneTimePrekey.
type OneTimePrekeyOutput struct {
	KeyID     int    `json:"key_id"`
	PublicKey string `json:"public_key"`
}
