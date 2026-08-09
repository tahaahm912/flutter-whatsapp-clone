let wasm_bindgen = (function(exports) {
    let script_src;
    if (typeof document !== 'undefined' && document.currentScript !== null) {
        script_src = new URL(document.currentScript.src, location.href).toString();
    }

    class WorkerPool {
        static __wrap(ptr) {
            const obj = Object.create(WorkerPool.prototype);
            obj.__wbg_ptr = ptr;
            WorkerPoolFinalization.register(obj, obj.__wbg_ptr, obj);
            return obj;
        }
        __destroy_into_raw() {
            const ptr = this.__wbg_ptr;
            this.__wbg_ptr = 0;
            WorkerPoolFinalization.unregister(this);
            return ptr;
        }
        free() {
            const ptr = this.__destroy_into_raw();
            wasm.__wbg_workerpool_free(ptr, 0);
        }
        /**
         * @param {number | null} [initial]
         * @param {string | null} [script_src]
         * @param {string | null} [worker_js_preamble]
         * @param {string | null} [wasm_bindgen_name]
         * @returns {WorkerPool}
         */
        static new(initial, script_src, worker_js_preamble, wasm_bindgen_name) {
            var ptr0 = isLikeNone(script_src) ? 0 : passStringToWasm0(script_src, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            var len0 = WASM_VECTOR_LEN;
            var ptr1 = isLikeNone(worker_js_preamble) ? 0 : passStringToWasm0(worker_js_preamble, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            var len1 = WASM_VECTOR_LEN;
            var ptr2 = isLikeNone(wasm_bindgen_name) ? 0 : passStringToWasm0(wasm_bindgen_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            var len2 = WASM_VECTOR_LEN;
            const ret = wasm.workerpool_new(isLikeNone(initial) ? Number.MAX_SAFE_INTEGER : (initial) >>> 0, ptr0, len0, ptr1, len1, ptr2, len2);
            if (ret[2]) {
                throw takeFromExternrefTable0(ret[1]);
            }
            return WorkerPool.__wrap(ret[0]);
        }
        /**
         * Creates a new `WorkerPool` which immediately creates `initial` workers.
         *
         * The pool created here can be used over a long period of time, and it
         * will be initially primed with `initial` workers. Currently workers are
         * never released or gc'd until the whole pool is destroyed.
         *
         * # Errors
         *
         * Returns any error that may happen while a JS web worker is created and a
         * message is sent to it.
         * @param {number} initial
         * @param {string} script_src
         * @param {string} worker_js_preamble
         * @param {string} wasm_bindgen_name
         */
        constructor(initial, script_src, worker_js_preamble, wasm_bindgen_name) {
            const ptr0 = passStringToWasm0(script_src, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            const len0 = WASM_VECTOR_LEN;
            const ptr1 = passStringToWasm0(worker_js_preamble, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            const len1 = WASM_VECTOR_LEN;
            const ptr2 = passStringToWasm0(wasm_bindgen_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            const len2 = WASM_VECTOR_LEN;
            const ret = wasm.workerpool_new_raw(initial, ptr0, len0, ptr1, len1, ptr2, len2);
            if (ret[2]) {
                throw takeFromExternrefTable0(ret[1]);
            }
            this.__wbg_ptr = ret[0];
            WorkerPoolFinalization.register(this, this.__wbg_ptr, this);
            return this;
        }
    }
    if (Symbol.dispose) WorkerPool.prototype[Symbol.dispose] = WorkerPool.prototype.free;
    exports.WorkerPool = WorkerPool;

    /**
     * @param {number} call_id
     * @param {any} ptr_
     * @param {number} rust_vec_len_
     * @param {number} data_len_
     */
    function frb_dart_fn_deliver_output(call_id, ptr_, rust_vec_len_, data_len_) {
        wasm.frb_dart_fn_deliver_output(call_id, ptr_, rust_vec_len_, data_len_);
    }
    exports.frb_dart_fn_deliver_output = frb_dart_fn_deliver_output;

    /**
     * # Safety
     *
     * This should never be called manually.
     * @param {any} handle
     * @param {any} dart_handler_port
     * @returns {number}
     */
    function frb_dart_opaque_dart2rust_encode(handle, dart_handler_port) {
        const ret = wasm.frb_dart_opaque_dart2rust_encode(handle, dart_handler_port);
        return ret >>> 0;
    }
    exports.frb_dart_opaque_dart2rust_encode = frb_dart_opaque_dart2rust_encode;

    /**
     * @param {number} ptr
     */
    function frb_dart_opaque_drop_thread_box_persistent_handle(ptr) {
        wasm.frb_dart_opaque_drop_thread_box_persistent_handle(ptr);
    }
    exports.frb_dart_opaque_drop_thread_box_persistent_handle = frb_dart_opaque_drop_thread_box_persistent_handle;

    /**
     * @param {number} ptr
     * @returns {any}
     */
    function frb_dart_opaque_rust2dart_decode(ptr) {
        const ret = wasm.frb_dart_opaque_rust2dart_decode(ptr);
        return ret;
    }
    exports.frb_dart_opaque_rust2dart_decode = frb_dart_opaque_rust2dart_decode;

    /**
     * @returns {number}
     */
    function frb_get_rust_content_hash() {
        const ret = wasm.frb_get_rust_content_hash();
        return ret;
    }
    exports.frb_get_rust_content_hash = frb_get_rust_content_hash;

    /**
     * @param {number} func_id
     * @param {any} port_
     * @param {any} ptr_
     * @param {number} rust_vec_len_
     * @param {number} data_len_
     */
    function frb_pde_ffi_dispatcher_primary(func_id, port_, ptr_, rust_vec_len_, data_len_) {
        wasm.frb_pde_ffi_dispatcher_primary(func_id, port_, ptr_, rust_vec_len_, data_len_);
    }
    exports.frb_pde_ffi_dispatcher_primary = frb_pde_ffi_dispatcher_primary;

    /**
     * @param {number} func_id
     * @param {any} ptr_
     * @param {number} rust_vec_len_
     * @param {number} data_len_
     * @returns {any}
     */
    function frb_pde_ffi_dispatcher_sync(func_id, ptr_, rust_vec_len_, data_len_) {
        const ret = wasm.frb_pde_ffi_dispatcher_sync(func_id, ptr_, rust_vec_len_, data_len_);
        return ret;
    }
    exports.frb_pde_ffi_dispatcher_sync = frb_pde_ffi_dispatcher_sync;

    /**
     * ## Safety
     * This function reclaims a raw pointer created by [`TransferClosure`], and therefore
     * should **only** be used in conjunction with it.
     * Furthermore, the WASM module in the worker must have been initialized with the shared
     * memory from the host JS scope.
     * @param {number} payload
     * @param {any[]} transfer
     */
    function receive_transfer_closure(payload, transfer) {
        const ptr0 = passArrayJsValueToWasm0(transfer, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.receive_transfer_closure(payload, ptr0, len0);
        if (ret[1]) {
            throw takeFromExternrefTable0(ret[0]);
        }
    }
    exports.receive_transfer_closure = receive_transfer_closure;

    /**
     * @param {number} ptr
     */
    function rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerAes256GcmSiv(ptr) {
        wasm.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerAes256GcmSiv(ptr);
    }
    exports.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerAes256GcmSiv = rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerAes256GcmSiv;

    /**
     * @param {number} ptr
     */
    function rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerDecryptionErrorMessage(ptr) {
        wasm.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerDecryptionErrorMessage(ptr);
    }
    exports.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerDecryptionErrorMessage = rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerDecryptionErrorMessage;

    /**
     * @param {number} ptr
     */
    function rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerFingerprint(ptr) {
        wasm.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerFingerprint(ptr);
    }
    exports.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerFingerprint = rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerFingerprint;

    /**
     * @param {number} ptr
     */
    function rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerIdentityKeyPair(ptr) {
        wasm.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerIdentityKeyPair(ptr);
    }
    exports.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerIdentityKeyPair = rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerIdentityKeyPair;

    /**
     * @param {number} ptr
     */
    function rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberKeyPair(ptr) {
        wasm.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberKeyPair(ptr);
    }
    exports.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberKeyPair = rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberKeyPair;

    /**
     * @param {number} ptr
     */
    function rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberPreKeyRecord(ptr) {
        wasm.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberPreKeyRecord(ptr);
    }
    exports.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberPreKeyRecord = rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberPreKeyRecord;

    /**
     * @param {number} ptr
     */
    function rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberPublicKey(ptr) {
        wasm.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberPublicKey(ptr);
    }
    exports.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberPublicKey = rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberPublicKey;

    /**
     * @param {number} ptr
     */
    function rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberSecretKey(ptr) {
        wasm.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberSecretKey(ptr);
    }
    exports.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberSecretKey = rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberSecretKey;

    /**
     * @param {number} ptr
     */
    function rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPreKeyBundle(ptr) {
        wasm.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPreKeyBundle(ptr);
    }
    exports.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPreKeyBundle = rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPreKeyBundle;

    /**
     * @param {number} ptr
     */
    function rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPreKeyRecord(ptr) {
        wasm.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPreKeyRecord(ptr);
    }
    exports.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPreKeyRecord = rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPreKeyRecord;

    /**
     * @param {number} ptr
     */
    function rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPrivateKey(ptr) {
        wasm.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPrivateKey(ptr);
    }
    exports.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPrivateKey = rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPrivateKey;

    /**
     * @param {number} ptr
     */
    function rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerProtocolAddress(ptr) {
        wasm.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerProtocolAddress(ptr);
    }
    exports.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerProtocolAddress = rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerProtocolAddress;

    /**
     * @param {number} ptr
     */
    function rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPublicKey(ptr) {
        wasm.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPublicKey(ptr);
    }
    exports.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPublicKey = rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPublicKey;

    /**
     * @param {number} ptr
     */
    function rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSessionRecord(ptr) {
        wasm.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSessionRecord(ptr);
    }
    exports.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSessionRecord = rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSessionRecord;

    /**
     * @param {number} ptr
     */
    function rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSignalMessage(ptr) {
        wasm.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSignalMessage(ptr);
    }
    exports.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSignalMessage = rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSignalMessage;

    /**
     * @param {number} ptr
     */
    function rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSignedPreKeyRecord(ptr) {
        wasm.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSignedPreKeyRecord(ptr);
    }
    exports.rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSignedPreKeyRecord = rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSignedPreKeyRecord;

    /**
     * @param {number} ptr
     */
    function rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerAes256GcmSiv(ptr) {
        wasm.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerAes256GcmSiv(ptr);
    }
    exports.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerAes256GcmSiv = rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerAes256GcmSiv;

    /**
     * @param {number} ptr
     */
    function rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerDecryptionErrorMessage(ptr) {
        wasm.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerDecryptionErrorMessage(ptr);
    }
    exports.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerDecryptionErrorMessage = rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerDecryptionErrorMessage;

    /**
     * @param {number} ptr
     */
    function rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerFingerprint(ptr) {
        wasm.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerFingerprint(ptr);
    }
    exports.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerFingerprint = rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerFingerprint;

    /**
     * @param {number} ptr
     */
    function rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerIdentityKeyPair(ptr) {
        wasm.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerIdentityKeyPair(ptr);
    }
    exports.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerIdentityKeyPair = rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerIdentityKeyPair;

    /**
     * @param {number} ptr
     */
    function rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberKeyPair(ptr) {
        wasm.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberKeyPair(ptr);
    }
    exports.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberKeyPair = rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberKeyPair;

    /**
     * @param {number} ptr
     */
    function rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberPreKeyRecord(ptr) {
        wasm.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberPreKeyRecord(ptr);
    }
    exports.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberPreKeyRecord = rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberPreKeyRecord;

    /**
     * @param {number} ptr
     */
    function rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberPublicKey(ptr) {
        wasm.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberPublicKey(ptr);
    }
    exports.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberPublicKey = rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberPublicKey;

    /**
     * @param {number} ptr
     */
    function rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberSecretKey(ptr) {
        wasm.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberSecretKey(ptr);
    }
    exports.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberSecretKey = rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerKyberSecretKey;

    /**
     * @param {number} ptr
     */
    function rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPreKeyBundle(ptr) {
        wasm.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPreKeyBundle(ptr);
    }
    exports.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPreKeyBundle = rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPreKeyBundle;

    /**
     * @param {number} ptr
     */
    function rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPreKeyRecord(ptr) {
        wasm.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPreKeyRecord(ptr);
    }
    exports.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPreKeyRecord = rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPreKeyRecord;

    /**
     * @param {number} ptr
     */
    function rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPrivateKey(ptr) {
        wasm.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPrivateKey(ptr);
    }
    exports.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPrivateKey = rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPrivateKey;

    /**
     * @param {number} ptr
     */
    function rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerProtocolAddress(ptr) {
        wasm.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerProtocolAddress(ptr);
    }
    exports.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerProtocolAddress = rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerProtocolAddress;

    /**
     * @param {number} ptr
     */
    function rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPublicKey(ptr) {
        wasm.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPublicKey(ptr);
    }
    exports.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPublicKey = rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPublicKey;

    /**
     * @param {number} ptr
     */
    function rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSessionRecord(ptr) {
        wasm.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSessionRecord(ptr);
    }
    exports.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSessionRecord = rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSessionRecord;

    /**
     * @param {number} ptr
     */
    function rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSignalMessage(ptr) {
        wasm.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSignalMessage(ptr);
    }
    exports.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSignalMessage = rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSignalMessage;

    /**
     * @param {number} ptr
     */
    function rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSignedPreKeyRecord(ptr) {
        wasm.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSignedPreKeyRecord(ptr);
    }
    exports.rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSignedPreKeyRecord = rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerSignedPreKeyRecord;

    function wasm_start_callback() {
        wasm.wasm_start_callback();
    }
    exports.wasm_start_callback = wasm_start_callback;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__address__ProtocolAddress_device_id(that) {
        const ret = wasm.wire__crate__api__address__ProtocolAddress_device_id(that);
        return ret;
    }
    exports.wire__crate__api__address__ProtocolAddress_device_id = wire__crate__api__address__ProtocolAddress_device_id;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__address__ProtocolAddress_name(that) {
        const ret = wasm.wire__crate__api__address__ProtocolAddress_name(that);
        return ret;
    }
    exports.wire__crate__api__address__ProtocolAddress_name = wire__crate__api__address__ProtocolAddress_name;

    /**
     * @param {string} name
     * @param {number} device_id
     * @returns {any}
     */
    function wire__crate__api__address__ProtocolAddress_new(name, device_id) {
        const ptr0 = passStringToWasm0(name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__address__ProtocolAddress_new(ptr0, len0, device_id);
        return ret;
    }
    exports.wire__crate__api__address__ProtocolAddress_new = wire__crate__api__address__ProtocolAddress_new;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__bundle__PreKeyBundle_device_id(that) {
        const ret = wasm.wire__crate__api__bundle__PreKeyBundle_device_id(that);
        return ret;
    }
    exports.wire__crate__api__bundle__PreKeyBundle_device_id = wire__crate__api__bundle__PreKeyBundle_device_id;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__bundle__PreKeyBundle_identity_key(that) {
        const ret = wasm.wire__crate__api__bundle__PreKeyBundle_identity_key(that);
        return ret;
    }
    exports.wire__crate__api__bundle__PreKeyBundle_identity_key = wire__crate__api__bundle__PreKeyBundle_identity_key;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__bundle__PreKeyBundle_kyber_pre_key_id(that) {
        const ret = wasm.wire__crate__api__bundle__PreKeyBundle_kyber_pre_key_id(that);
        return ret;
    }
    exports.wire__crate__api__bundle__PreKeyBundle_kyber_pre_key_id = wire__crate__api__bundle__PreKeyBundle_kyber_pre_key_id;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__bundle__PreKeyBundle_kyber_pre_key_public(that) {
        const ret = wasm.wire__crate__api__bundle__PreKeyBundle_kyber_pre_key_public(that);
        return ret;
    }
    exports.wire__crate__api__bundle__PreKeyBundle_kyber_pre_key_public = wire__crate__api__bundle__PreKeyBundle_kyber_pre_key_public;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__bundle__PreKeyBundle_kyber_pre_key_signature(that) {
        const ret = wasm.wire__crate__api__bundle__PreKeyBundle_kyber_pre_key_signature(that);
        return ret;
    }
    exports.wire__crate__api__bundle__PreKeyBundle_kyber_pre_key_signature = wire__crate__api__bundle__PreKeyBundle_kyber_pre_key_signature;

    /**
     * @param {number} registration_id
     * @param {number} device_id
     * @param {any} pre_key_id
     * @param {Uint8Array | null | undefined} pre_key_public
     * @param {number} signed_pre_key_id
     * @param {Uint8Array} signed_pre_key_public
     * @param {Uint8Array} signed_pre_key_signature
     * @param {Uint8Array} identity_key
     * @param {number} kyber_pre_key_id
     * @param {Uint8Array} kyber_pre_key_public
     * @param {Uint8Array} kyber_pre_key_signature
     * @returns {any}
     */
    function wire__crate__api__bundle__PreKeyBundle_new(registration_id, device_id, pre_key_id, pre_key_public, signed_pre_key_id, signed_pre_key_public, signed_pre_key_signature, identity_key, kyber_pre_key_id, kyber_pre_key_public, kyber_pre_key_signature) {
        var ptr0 = isLikeNone(pre_key_public) ? 0 : passArray8ToWasm0(pre_key_public, wasm.__wbindgen_malloc);
        var len0 = WASM_VECTOR_LEN;
        const ptr1 = passArray8ToWasm0(signed_pre_key_public, wasm.__wbindgen_malloc);
        const len1 = WASM_VECTOR_LEN;
        const ptr2 = passArray8ToWasm0(signed_pre_key_signature, wasm.__wbindgen_malloc);
        const len2 = WASM_VECTOR_LEN;
        const ptr3 = passArray8ToWasm0(identity_key, wasm.__wbindgen_malloc);
        const len3 = WASM_VECTOR_LEN;
        const ptr4 = passArray8ToWasm0(kyber_pre_key_public, wasm.__wbindgen_malloc);
        const len4 = WASM_VECTOR_LEN;
        const ptr5 = passArray8ToWasm0(kyber_pre_key_signature, wasm.__wbindgen_malloc);
        const len5 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__bundle__PreKeyBundle_new(registration_id, device_id, pre_key_id, ptr0, len0, signed_pre_key_id, ptr1, len1, ptr2, len2, ptr3, len3, kyber_pre_key_id, ptr4, len4, ptr5, len5);
        return ret;
    }
    exports.wire__crate__api__bundle__PreKeyBundle_new = wire__crate__api__bundle__PreKeyBundle_new;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__bundle__PreKeyBundle_pre_key_id(that) {
        const ret = wasm.wire__crate__api__bundle__PreKeyBundle_pre_key_id(that);
        return ret;
    }
    exports.wire__crate__api__bundle__PreKeyBundle_pre_key_id = wire__crate__api__bundle__PreKeyBundle_pre_key_id;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__bundle__PreKeyBundle_pre_key_public(that) {
        const ret = wasm.wire__crate__api__bundle__PreKeyBundle_pre_key_public(that);
        return ret;
    }
    exports.wire__crate__api__bundle__PreKeyBundle_pre_key_public = wire__crate__api__bundle__PreKeyBundle_pre_key_public;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__bundle__PreKeyBundle_registration_id(that) {
        const ret = wasm.wire__crate__api__bundle__PreKeyBundle_registration_id(that);
        return ret;
    }
    exports.wire__crate__api__bundle__PreKeyBundle_registration_id = wire__crate__api__bundle__PreKeyBundle_registration_id;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__bundle__PreKeyBundle_signed_pre_key_id(that) {
        const ret = wasm.wire__crate__api__bundle__PreKeyBundle_signed_pre_key_id(that);
        return ret;
    }
    exports.wire__crate__api__bundle__PreKeyBundle_signed_pre_key_id = wire__crate__api__bundle__PreKeyBundle_signed_pre_key_id;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__bundle__PreKeyBundle_signed_pre_key_public(that) {
        const ret = wasm.wire__crate__api__bundle__PreKeyBundle_signed_pre_key_public(that);
        return ret;
    }
    exports.wire__crate__api__bundle__PreKeyBundle_signed_pre_key_public = wire__crate__api__bundle__PreKeyBundle_signed_pre_key_public;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__bundle__PreKeyBundle_signed_pre_key_signature(that) {
        const ret = wasm.wire__crate__api__bundle__PreKeyBundle_signed_pre_key_signature(that);
        return ret;
    }
    exports.wire__crate__api__bundle__PreKeyBundle_signed_pre_key_signature = wire__crate__api__bundle__PreKeyBundle_signed_pre_key_signature;

    /**
     * @param {any} that
     * @param {Uint8Array} ciphertext
     * @param {Uint8Array} nonce
     * @param {Uint8Array} associated_data
     * @returns {any}
     */
    function wire__crate__api__crypto__Aes256GcmSiv_decrypt(that, ciphertext, nonce, associated_data) {
        const ptr0 = passArray8ToWasm0(ciphertext, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passArray8ToWasm0(nonce, wasm.__wbindgen_malloc);
        const len1 = WASM_VECTOR_LEN;
        const ptr2 = passArray8ToWasm0(associated_data, wasm.__wbindgen_malloc);
        const len2 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__crypto__Aes256GcmSiv_decrypt(that, ptr0, len0, ptr1, len1, ptr2, len2);
        return ret;
    }
    exports.wire__crate__api__crypto__Aes256GcmSiv_decrypt = wire__crate__api__crypto__Aes256GcmSiv_decrypt;

    /**
     * @param {any} that
     * @param {Uint8Array} plaintext
     * @param {Uint8Array} nonce
     * @param {Uint8Array} associated_data
     * @returns {any}
     */
    function wire__crate__api__crypto__Aes256GcmSiv_encrypt(that, plaintext, nonce, associated_data) {
        const ptr0 = passArray8ToWasm0(plaintext, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passArray8ToWasm0(nonce, wasm.__wbindgen_malloc);
        const len1 = WASM_VECTOR_LEN;
        const ptr2 = passArray8ToWasm0(associated_data, wasm.__wbindgen_malloc);
        const len2 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__crypto__Aes256GcmSiv_encrypt(that, ptr0, len0, ptr1, len1, ptr2, len2);
        return ret;
    }
    exports.wire__crate__api__crypto__Aes256GcmSiv_encrypt = wire__crate__api__crypto__Aes256GcmSiv_encrypt;

    /**
     * @param {Uint8Array} key
     * @returns {any}
     */
    function wire__crate__api__crypto__Aes256GcmSiv_new(key) {
        const ptr0 = passArray8ToWasm0(key, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__crypto__Aes256GcmSiv_new(ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__crypto__Aes256GcmSiv_new = wire__crate__api__crypto__Aes256GcmSiv_new;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__crypto__Fingerprint_clone_fingerprint(that) {
        const ret = wasm.wire__crate__api__crypto__Fingerprint_clone_fingerprint(that);
        return ret;
    }
    exports.wire__crate__api__crypto__Fingerprint_clone_fingerprint = wire__crate__api__crypto__Fingerprint_clone_fingerprint;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__crypto__Fingerprint_display_string(that) {
        const ret = wasm.wire__crate__api__crypto__Fingerprint_display_string(that);
        return ret;
    }
    exports.wire__crate__api__crypto__Fingerprint_display_string = wire__crate__api__crypto__Fingerprint_display_string;

    /**
     * @param {number} iterations
     * @param {number} version
     * @param {Uint8Array} local_identifier
     * @param {Uint8Array} local_public_key
     * @param {Uint8Array} remote_identifier
     * @param {Uint8Array} remote_public_key
     * @returns {any}
     */
    function wire__crate__api__crypto__Fingerprint_new(iterations, version, local_identifier, local_public_key, remote_identifier, remote_public_key) {
        const ptr0 = passArray8ToWasm0(local_identifier, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passArray8ToWasm0(local_public_key, wasm.__wbindgen_malloc);
        const len1 = WASM_VECTOR_LEN;
        const ptr2 = passArray8ToWasm0(remote_identifier, wasm.__wbindgen_malloc);
        const len2 = WASM_VECTOR_LEN;
        const ptr3 = passArray8ToWasm0(remote_public_key, wasm.__wbindgen_malloc);
        const len3 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__crypto__Fingerprint_new(iterations, version, ptr0, len0, ptr1, len1, ptr2, len2, ptr3, len3);
        return ret;
    }
    exports.wire__crate__api__crypto__Fingerprint_new = wire__crate__api__crypto__Fingerprint_new;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__crypto__Fingerprint_scannable_encoding(that) {
        const ret = wasm.wire__crate__api__crypto__Fingerprint_scannable_encoding(that);
        return ret;
    }
    exports.wire__crate__api__crypto__Fingerprint_scannable_encoding = wire__crate__api__crypto__Fingerprint_scannable_encoding;

    /**
     * @param {Uint8Array} fingerprint1
     * @param {Uint8Array} fingerprint2
     * @returns {any}
     */
    function wire__crate__api__crypto__fingerprint_compare(fingerprint1, fingerprint2) {
        const ptr0 = passArray8ToWasm0(fingerprint1, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passArray8ToWasm0(fingerprint2, wasm.__wbindgen_malloc);
        const len1 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__crypto__fingerprint_compare(ptr0, len0, ptr1, len1);
        return ret;
    }
    exports.wire__crate__api__crypto__fingerprint_compare = wire__crate__api__crypto__fingerprint_compare;

    /**
     * @param {number} output_length
     * @param {Uint8Array} input_key_material
     * @param {Uint8Array} salt
     * @param {Uint8Array} info
     * @returns {any}
     */
    function wire__crate__api__crypto__hkdf_derive(output_length, input_key_material, salt, info) {
        const ptr0 = passArray8ToWasm0(input_key_material, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passArray8ToWasm0(salt, wasm.__wbindgen_malloc);
        const len1 = WASM_VECTOR_LEN;
        const ptr2 = passArray8ToWasm0(info, wasm.__wbindgen_malloc);
        const len2 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__crypto__hkdf_derive(output_length, ptr0, len0, ptr1, len1, ptr2, len2);
        return ret;
    }
    exports.wire__crate__api__crypto__hkdf_derive = wire__crate__api__crypto__hkdf_derive;

    /**
     * @param {any} port_
     * @param {string} sender_name
     * @param {number} sender_device_id
     * @param {string} distribution_id
     * @param {any} load_sender_key
     * @param {any} store_sender_key
     * @param {any} get_identity_key_pair
     */
    function wire__crate__api__group_session__create_sender_key_distribution_message_with_callbacks(port_, sender_name, sender_device_id, distribution_id, load_sender_key, store_sender_key, get_identity_key_pair) {
        const ptr0 = passStringToWasm0(sender_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(distribution_id, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        wasm.wire__crate__api__group_session__create_sender_key_distribution_message_with_callbacks(port_, ptr0, len0, sender_device_id, ptr1, len1, load_sender_key, store_sender_key, get_identity_key_pair);
    }
    exports.wire__crate__api__group_session__create_sender_key_distribution_message_with_callbacks = wire__crate__api__group_session__create_sender_key_distribution_message_with_callbacks;

    /**
     * @param {any} port_
     * @param {string} sender_name
     * @param {number} sender_device_id
     * @param {string} distribution_id
     * @param {Uint8Array} ciphertext
     * @param {any} load_sender_key
     * @param {any} store_sender_key
     */
    function wire__crate__api__group_session__group_decrypt_with_callbacks(port_, sender_name, sender_device_id, distribution_id, ciphertext, load_sender_key, store_sender_key) {
        const ptr0 = passStringToWasm0(sender_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(distribution_id, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        const ptr2 = passArray8ToWasm0(ciphertext, wasm.__wbindgen_malloc);
        const len2 = WASM_VECTOR_LEN;
        wasm.wire__crate__api__group_session__group_decrypt_with_callbacks(port_, ptr0, len0, sender_device_id, ptr1, len1, ptr2, len2, load_sender_key, store_sender_key);
    }
    exports.wire__crate__api__group_session__group_decrypt_with_callbacks = wire__crate__api__group_session__group_decrypt_with_callbacks;

    /**
     * @param {any} port_
     * @param {string} sender_name
     * @param {number} sender_device_id
     * @param {string} distribution_id
     * @param {Uint8Array} plaintext
     * @param {any} load_sender_key
     * @param {any} store_sender_key
     * @param {any} get_identity_key_pair
     */
    function wire__crate__api__group_session__group_encrypt_with_callbacks(port_, sender_name, sender_device_id, distribution_id, plaintext, load_sender_key, store_sender_key, get_identity_key_pair) {
        const ptr0 = passStringToWasm0(sender_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(distribution_id, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        const ptr2 = passArray8ToWasm0(plaintext, wasm.__wbindgen_malloc);
        const len2 = WASM_VECTOR_LEN;
        wasm.wire__crate__api__group_session__group_encrypt_with_callbacks(port_, ptr0, len0, sender_device_id, ptr1, len1, ptr2, len2, load_sender_key, store_sender_key, get_identity_key_pair);
    }
    exports.wire__crate__api__group_session__group_encrypt_with_callbacks = wire__crate__api__group_session__group_encrypt_with_callbacks;

    /**
     * @param {any} port_
     * @param {string} sender_name
     * @param {number} sender_device_id
     * @param {string} distribution_id
     * @param {Uint8Array} distribution_message
     * @param {any} load_sender_key
     * @param {any} store_sender_key
     */
    function wire__crate__api__group_session__process_sender_key_distribution_message_with_callbacks(port_, sender_name, sender_device_id, distribution_id, distribution_message, load_sender_key, store_sender_key) {
        const ptr0 = passStringToWasm0(sender_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(distribution_id, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        const ptr2 = passArray8ToWasm0(distribution_message, wasm.__wbindgen_malloc);
        const len2 = WASM_VECTOR_LEN;
        wasm.wire__crate__api__group_session__process_sender_key_distribution_message_with_callbacks(port_, ptr0, len0, sender_device_id, ptr1, len1, ptr2, len2, load_sender_key, store_sender_key);
    }
    exports.wire__crate__api__group_session__process_sender_key_distribution_message_with_callbacks = wire__crate__api__group_session__process_sender_key_distribution_message_with_callbacks;

    /**
     * @param {string} _library_path
     * @returns {any}
     */
    function wire__crate__api__init__init_libsignal(_library_path) {
        const ptr0 = passStringToWasm0(_library_path, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__init__init_libsignal(ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__init__init_libsignal = wire__crate__api__init__init_libsignal;

    /**
     * @returns {any}
     */
    function wire__crate__api__init__is_libsignal_initialized() {
        const ret = wasm.wire__crate__api__init__is_libsignal_initialized();
        return ret;
    }
    exports.wire__crate__api__init__is_libsignal_initialized = wire__crate__api__init__is_libsignal_initialized;

    /**
     * @param {Uint8Array} bytes
     * @returns {any}
     */
    function wire__crate__api__keys__IdentityKeyPair_deserialize(bytes) {
        const ptr0 = passArray8ToWasm0(bytes, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__keys__IdentityKeyPair_deserialize(ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__keys__IdentityKeyPair_deserialize = wire__crate__api__keys__IdentityKeyPair_deserialize;

    /**
     * @param {any} private_key
     * @param {any} public_key
     * @returns {any}
     */
    function wire__crate__api__keys__IdentityKeyPair_from_keys(private_key, public_key) {
        const ret = wasm.wire__crate__api__keys__IdentityKeyPair_from_keys(private_key, public_key);
        return ret;
    }
    exports.wire__crate__api__keys__IdentityKeyPair_from_keys = wire__crate__api__keys__IdentityKeyPair_from_keys;

    /**
     * @returns {any}
     */
    function wire__crate__api__keys__IdentityKeyPair_generate() {
        const ret = wasm.wire__crate__api__keys__IdentityKeyPair_generate();
        return ret;
    }
    exports.wire__crate__api__keys__IdentityKeyPair_generate = wire__crate__api__keys__IdentityKeyPair_generate;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__keys__IdentityKeyPair_private_key(that) {
        const ret = wasm.wire__crate__api__keys__IdentityKeyPair_private_key(that);
        return ret;
    }
    exports.wire__crate__api__keys__IdentityKeyPair_private_key = wire__crate__api__keys__IdentityKeyPair_private_key;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__keys__IdentityKeyPair_public_key(that) {
        const ret = wasm.wire__crate__api__keys__IdentityKeyPair_public_key(that);
        return ret;
    }
    exports.wire__crate__api__keys__IdentityKeyPair_public_key = wire__crate__api__keys__IdentityKeyPair_public_key;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__keys__IdentityKeyPair_serialize(that) {
        const ret = wasm.wire__crate__api__keys__IdentityKeyPair_serialize(that);
        return ret;
    }
    exports.wire__crate__api__keys__IdentityKeyPair_serialize = wire__crate__api__keys__IdentityKeyPair_serialize;

    /**
     * @param {any} that
     * @param {any} other_identity
     * @returns {any}
     */
    function wire__crate__api__keys__IdentityKeyPair_sign_alternate_identity(that, other_identity) {
        const ret = wasm.wire__crate__api__keys__IdentityKeyPair_sign_alternate_identity(that, other_identity);
        return ret;
    }
    exports.wire__crate__api__keys__IdentityKeyPair_sign_alternate_identity = wire__crate__api__keys__IdentityKeyPair_sign_alternate_identity;

    /**
     * @param {any} that
     * @param {any} public_key
     * @returns {any}
     */
    function wire__crate__api__keys__PrivateKey_agree(that, public_key) {
        const ret = wasm.wire__crate__api__keys__PrivateKey_agree(that, public_key);
        return ret;
    }
    exports.wire__crate__api__keys__PrivateKey_agree = wire__crate__api__keys__PrivateKey_agree;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__keys__PrivateKey_clone_key(that) {
        const ret = wasm.wire__crate__api__keys__PrivateKey_clone_key(that);
        return ret;
    }
    exports.wire__crate__api__keys__PrivateKey_clone_key = wire__crate__api__keys__PrivateKey_clone_key;

    /**
     * @param {Uint8Array} bytes
     * @returns {any}
     */
    function wire__crate__api__keys__PrivateKey_deserialize(bytes) {
        const ptr0 = passArray8ToWasm0(bytes, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__keys__PrivateKey_deserialize(ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__keys__PrivateKey_deserialize = wire__crate__api__keys__PrivateKey_deserialize;

    /**
     * @returns {any}
     */
    function wire__crate__api__keys__PrivateKey_generate() {
        const ret = wasm.wire__crate__api__keys__PrivateKey_generate();
        return ret;
    }
    exports.wire__crate__api__keys__PrivateKey_generate = wire__crate__api__keys__PrivateKey_generate;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__keys__PrivateKey_get_public_key(that) {
        const ret = wasm.wire__crate__api__keys__PrivateKey_get_public_key(that);
        return ret;
    }
    exports.wire__crate__api__keys__PrivateKey_get_public_key = wire__crate__api__keys__PrivateKey_get_public_key;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__keys__PrivateKey_serialize(that) {
        const ret = wasm.wire__crate__api__keys__PrivateKey_serialize(that);
        return ret;
    }
    exports.wire__crate__api__keys__PrivateKey_serialize = wire__crate__api__keys__PrivateKey_serialize;

    /**
     * @param {any} that
     * @param {Uint8Array} message
     * @returns {any}
     */
    function wire__crate__api__keys__PrivateKey_sign(that, message) {
        const ptr0 = passArray8ToWasm0(message, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__keys__PrivateKey_sign(that, ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__keys__PrivateKey_sign = wire__crate__api__keys__PrivateKey_sign;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__keys__PublicKey_clone_key(that) {
        const ret = wasm.wire__crate__api__keys__PublicKey_clone_key(that);
        return ret;
    }
    exports.wire__crate__api__keys__PublicKey_clone_key = wire__crate__api__keys__PublicKey_clone_key;

    /**
     * @param {any} that
     * @param {any} other
     * @returns {any}
     */
    function wire__crate__api__keys__PublicKey_compare(that, other) {
        const ret = wasm.wire__crate__api__keys__PublicKey_compare(that, other);
        return ret;
    }
    exports.wire__crate__api__keys__PublicKey_compare = wire__crate__api__keys__PublicKey_compare;

    /**
     * @param {Uint8Array} bytes
     * @returns {any}
     */
    function wire__crate__api__keys__PublicKey_deserialize(bytes) {
        const ptr0 = passArray8ToWasm0(bytes, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__keys__PublicKey_deserialize(ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__keys__PublicKey_deserialize = wire__crate__api__keys__PublicKey_deserialize;

    /**
     * @param {any} that
     * @param {any} other
     * @returns {any}
     */
    function wire__crate__api__keys__PublicKey_equals(that, other) {
        const ret = wasm.wire__crate__api__keys__PublicKey_equals(that, other);
        return ret;
    }
    exports.wire__crate__api__keys__PublicKey_equals = wire__crate__api__keys__PublicKey_equals;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__keys__PublicKey_get_public_key_bytes(that) {
        const ret = wasm.wire__crate__api__keys__PublicKey_get_public_key_bytes(that);
        return ret;
    }
    exports.wire__crate__api__keys__PublicKey_get_public_key_bytes = wire__crate__api__keys__PublicKey_get_public_key_bytes;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__keys__PublicKey_serialize(that) {
        const ret = wasm.wire__crate__api__keys__PublicKey_serialize(that);
        return ret;
    }
    exports.wire__crate__api__keys__PublicKey_serialize = wire__crate__api__keys__PublicKey_serialize;

    /**
     * @param {any} that
     * @param {Uint8Array} message
     * @param {Uint8Array} signature
     * @returns {any}
     */
    function wire__crate__api__keys__PublicKey_verify(that, message, signature) {
        const ptr0 = passArray8ToWasm0(message, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passArray8ToWasm0(signature, wasm.__wbindgen_malloc);
        const len1 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__keys__PublicKey_verify(that, ptr0, len0, ptr1, len1);
        return ret;
    }
    exports.wire__crate__api__keys__PublicKey_verify = wire__crate__api__keys__PublicKey_verify;

    /**
     * @param {any} public_key
     * @param {any} private_key
     * @returns {any}
     */
    function wire__crate__api__keys__identity_keypair_serialize_raw(public_key, private_key) {
        const ret = wasm.wire__crate__api__keys__identity_keypair_serialize_raw(public_key, private_key);
        return ret;
    }
    exports.wire__crate__api__keys__identity_keypair_serialize_raw = wire__crate__api__keys__identity_keypair_serialize_raw;

    /**
     * @param {any} public_key
     * @param {any} private_key
     * @param {any} other_identity
     * @returns {any}
     */
    function wire__crate__api__keys__identity_keypair_sign_alternate_identity_raw(public_key, private_key, other_identity) {
        const ret = wasm.wire__crate__api__keys__identity_keypair_sign_alternate_identity_raw(public_key, private_key, other_identity);
        return ret;
    }
    exports.wire__crate__api__keys__identity_keypair_sign_alternate_identity_raw = wire__crate__api__keys__identity_keypair_sign_alternate_identity_raw;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__kyber__KyberKeyPair_clone_key(that) {
        const ret = wasm.wire__crate__api__kyber__KyberKeyPair_clone_key(that);
        return ret;
    }
    exports.wire__crate__api__kyber__KyberKeyPair_clone_key = wire__crate__api__kyber__KyberKeyPair_clone_key;

    /**
     * @returns {any}
     */
    function wire__crate__api__kyber__KyberKeyPair_generate() {
        const ret = wasm.wire__crate__api__kyber__KyberKeyPair_generate();
        return ret;
    }
    exports.wire__crate__api__kyber__KyberKeyPair_generate = wire__crate__api__kyber__KyberKeyPair_generate;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__kyber__KyberKeyPair_get_public_key(that) {
        const ret = wasm.wire__crate__api__kyber__KyberKeyPair_get_public_key(that);
        return ret;
    }
    exports.wire__crate__api__kyber__KyberKeyPair_get_public_key = wire__crate__api__kyber__KyberKeyPair_get_public_key;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__kyber__KyberKeyPair_get_secret_key(that) {
        const ret = wasm.wire__crate__api__kyber__KyberKeyPair_get_secret_key(that);
        return ret;
    }
    exports.wire__crate__api__kyber__KyberKeyPair_get_secret_key = wire__crate__api__kyber__KyberKeyPair_get_secret_key;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__kyber__KyberPreKeyRecord_clone_record(that) {
        const ret = wasm.wire__crate__api__kyber__KyberPreKeyRecord_clone_record(that);
        return ret;
    }
    exports.wire__crate__api__kyber__KyberPreKeyRecord_clone_record = wire__crate__api__kyber__KyberPreKeyRecord_clone_record;

    /**
     * @param {number} id
     * @param {any} timestamp
     * @param {any} key_pair
     * @param {Uint8Array} signature
     * @returns {any}
     */
    function wire__crate__api__kyber__KyberPreKeyRecord_create(id, timestamp, key_pair, signature) {
        const ptr0 = passArray8ToWasm0(signature, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__kyber__KyberPreKeyRecord_create(id, timestamp, key_pair, ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__kyber__KyberPreKeyRecord_create = wire__crate__api__kyber__KyberPreKeyRecord_create;

    /**
     * @param {Uint8Array} bytes
     * @returns {any}
     */
    function wire__crate__api__kyber__KyberPreKeyRecord_deserialize(bytes) {
        const ptr0 = passArray8ToWasm0(bytes, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__kyber__KyberPreKeyRecord_deserialize(ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__kyber__KyberPreKeyRecord_deserialize = wire__crate__api__kyber__KyberPreKeyRecord_deserialize;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__kyber__KyberPreKeyRecord_get_key_pair(that) {
        const ret = wasm.wire__crate__api__kyber__KyberPreKeyRecord_get_key_pair(that);
        return ret;
    }
    exports.wire__crate__api__kyber__KyberPreKeyRecord_get_key_pair = wire__crate__api__kyber__KyberPreKeyRecord_get_key_pair;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__kyber__KyberPreKeyRecord_get_public_key(that) {
        const ret = wasm.wire__crate__api__kyber__KyberPreKeyRecord_get_public_key(that);
        return ret;
    }
    exports.wire__crate__api__kyber__KyberPreKeyRecord_get_public_key = wire__crate__api__kyber__KyberPreKeyRecord_get_public_key;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__kyber__KyberPreKeyRecord_get_secret_key(that) {
        const ret = wasm.wire__crate__api__kyber__KyberPreKeyRecord_get_secret_key(that);
        return ret;
    }
    exports.wire__crate__api__kyber__KyberPreKeyRecord_get_secret_key = wire__crate__api__kyber__KyberPreKeyRecord_get_secret_key;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__kyber__KyberPreKeyRecord_id(that) {
        const ret = wasm.wire__crate__api__kyber__KyberPreKeyRecord_id(that);
        return ret;
    }
    exports.wire__crate__api__kyber__KyberPreKeyRecord_id = wire__crate__api__kyber__KyberPreKeyRecord_id;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__kyber__KyberPreKeyRecord_serialize(that) {
        const ret = wasm.wire__crate__api__kyber__KyberPreKeyRecord_serialize(that);
        return ret;
    }
    exports.wire__crate__api__kyber__KyberPreKeyRecord_serialize = wire__crate__api__kyber__KyberPreKeyRecord_serialize;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__kyber__KyberPreKeyRecord_signature(that) {
        const ret = wasm.wire__crate__api__kyber__KyberPreKeyRecord_signature(that);
        return ret;
    }
    exports.wire__crate__api__kyber__KyberPreKeyRecord_signature = wire__crate__api__kyber__KyberPreKeyRecord_signature;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__kyber__KyberPreKeyRecord_timestamp(that) {
        const ret = wasm.wire__crate__api__kyber__KyberPreKeyRecord_timestamp(that);
        return ret;
    }
    exports.wire__crate__api__kyber__KyberPreKeyRecord_timestamp = wire__crate__api__kyber__KyberPreKeyRecord_timestamp;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__kyber__KyberPublicKey_clone_key(that) {
        const ret = wasm.wire__crate__api__kyber__KyberPublicKey_clone_key(that);
        return ret;
    }
    exports.wire__crate__api__kyber__KyberPublicKey_clone_key = wire__crate__api__kyber__KyberPublicKey_clone_key;

    /**
     * @param {Uint8Array} bytes
     * @returns {any}
     */
    function wire__crate__api__kyber__KyberPublicKey_deserialize(bytes) {
        const ptr0 = passArray8ToWasm0(bytes, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__kyber__KyberPublicKey_deserialize(ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__kyber__KyberPublicKey_deserialize = wire__crate__api__kyber__KyberPublicKey_deserialize;

    /**
     * @param {any} that
     * @param {any} other
     * @returns {any}
     */
    function wire__crate__api__kyber__KyberPublicKey_equals(that, other) {
        const ret = wasm.wire__crate__api__kyber__KyberPublicKey_equals(that, other);
        return ret;
    }
    exports.wire__crate__api__kyber__KyberPublicKey_equals = wire__crate__api__kyber__KyberPublicKey_equals;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__kyber__KyberPublicKey_serialize(that) {
        const ret = wasm.wire__crate__api__kyber__KyberPublicKey_serialize(that);
        return ret;
    }
    exports.wire__crate__api__kyber__KyberPublicKey_serialize = wire__crate__api__kyber__KyberPublicKey_serialize;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__kyber__KyberSecretKey_clone_key(that) {
        const ret = wasm.wire__crate__api__kyber__KyberSecretKey_clone_key(that);
        return ret;
    }
    exports.wire__crate__api__kyber__KyberSecretKey_clone_key = wire__crate__api__kyber__KyberSecretKey_clone_key;

    /**
     * @param {Uint8Array} bytes
     * @returns {any}
     */
    function wire__crate__api__kyber__KyberSecretKey_deserialize(bytes) {
        const ptr0 = passArray8ToWasm0(bytes, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__kyber__KyberSecretKey_deserialize(ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__kyber__KyberSecretKey_deserialize = wire__crate__api__kyber__KyberSecretKey_deserialize;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__kyber__KyberSecretKey_serialize(that) {
        const ret = wasm.wire__crate__api__kyber__KyberSecretKey_serialize(that);
        return ret;
    }
    exports.wire__crate__api__kyber__KyberSecretKey_serialize = wire__crate__api__kyber__KyberSecretKey_serialize;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__message__DecryptionErrorMessage_clone_message(that) {
        const ret = wasm.wire__crate__api__message__DecryptionErrorMessage_clone_message(that);
        return ret;
    }
    exports.wire__crate__api__message__DecryptionErrorMessage_clone_message = wire__crate__api__message__DecryptionErrorMessage_clone_message;

    /**
     * @param {Uint8Array} bytes
     * @returns {any}
     */
    function wire__crate__api__message__DecryptionErrorMessage_deserialize(bytes) {
        const ptr0 = passArray8ToWasm0(bytes, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__message__DecryptionErrorMessage_deserialize(ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__message__DecryptionErrorMessage_deserialize = wire__crate__api__message__DecryptionErrorMessage_deserialize;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__message__DecryptionErrorMessage_device_id(that) {
        const ret = wasm.wire__crate__api__message__DecryptionErrorMessage_device_id(that);
        return ret;
    }
    exports.wire__crate__api__message__DecryptionErrorMessage_device_id = wire__crate__api__message__DecryptionErrorMessage_device_id;

    /**
     * @param {Uint8Array} bytes
     * @returns {any}
     */
    function wire__crate__api__message__DecryptionErrorMessage_extract_from_serialized_content(bytes) {
        const ptr0 = passArray8ToWasm0(bytes, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__message__DecryptionErrorMessage_extract_from_serialized_content(ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__message__DecryptionErrorMessage_extract_from_serialized_content = wire__crate__api__message__DecryptionErrorMessage_extract_from_serialized_content;

    /**
     * @param {Uint8Array} original_bytes
     * @param {number} message_type
     * @param {any} timestamp
     * @param {number} original_sender_device_id
     * @returns {any}
     */
    function wire__crate__api__message__DecryptionErrorMessage_for_original_message(original_bytes, message_type, timestamp, original_sender_device_id) {
        const ptr0 = passArray8ToWasm0(original_bytes, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__message__DecryptionErrorMessage_for_original_message(ptr0, len0, message_type, timestamp, original_sender_device_id);
        return ret;
    }
    exports.wire__crate__api__message__DecryptionErrorMessage_for_original_message = wire__crate__api__message__DecryptionErrorMessage_for_original_message;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__message__DecryptionErrorMessage_ratchet_key(that) {
        const ret = wasm.wire__crate__api__message__DecryptionErrorMessage_ratchet_key(that);
        return ret;
    }
    exports.wire__crate__api__message__DecryptionErrorMessage_ratchet_key = wire__crate__api__message__DecryptionErrorMessage_ratchet_key;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__message__DecryptionErrorMessage_serialize(that) {
        const ret = wasm.wire__crate__api__message__DecryptionErrorMessage_serialize(that);
        return ret;
    }
    exports.wire__crate__api__message__DecryptionErrorMessage_serialize = wire__crate__api__message__DecryptionErrorMessage_serialize;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__message__DecryptionErrorMessage_timestamp(that) {
        const ret = wasm.wire__crate__api__message__DecryptionErrorMessage_timestamp(that);
        return ret;
    }
    exports.wire__crate__api__message__DecryptionErrorMessage_timestamp = wire__crate__api__message__DecryptionErrorMessage_timestamp;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__message__SignalMessage_body(that) {
        const ret = wasm.wire__crate__api__message__SignalMessage_body(that);
        return ret;
    }
    exports.wire__crate__api__message__SignalMessage_body = wire__crate__api__message__SignalMessage_body;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__message__SignalMessage_clone_message(that) {
        const ret = wasm.wire__crate__api__message__SignalMessage_clone_message(that);
        return ret;
    }
    exports.wire__crate__api__message__SignalMessage_clone_message = wire__crate__api__message__SignalMessage_clone_message;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__message__SignalMessage_counter(that) {
        const ret = wasm.wire__crate__api__message__SignalMessage_counter(that);
        return ret;
    }
    exports.wire__crate__api__message__SignalMessage_counter = wire__crate__api__message__SignalMessage_counter;

    /**
     * @param {Uint8Array} data
     * @returns {any}
     */
    function wire__crate__api__message__SignalMessage_deserialize(data) {
        const ptr0 = passArray8ToWasm0(data, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__message__SignalMessage_deserialize(ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__message__SignalMessage_deserialize = wire__crate__api__message__SignalMessage_deserialize;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__message__SignalMessage_message_version(that) {
        const ret = wasm.wire__crate__api__message__SignalMessage_message_version(that);
        return ret;
    }
    exports.wire__crate__api__message__SignalMessage_message_version = wire__crate__api__message__SignalMessage_message_version;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__message__SignalMessage_pq_ratchet(that) {
        const ret = wasm.wire__crate__api__message__SignalMessage_pq_ratchet(that);
        return ret;
    }
    exports.wire__crate__api__message__SignalMessage_pq_ratchet = wire__crate__api__message__SignalMessage_pq_ratchet;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__message__SignalMessage_sender_ratchet_key(that) {
        const ret = wasm.wire__crate__api__message__SignalMessage_sender_ratchet_key(that);
        return ret;
    }
    exports.wire__crate__api__message__SignalMessage_sender_ratchet_key = wire__crate__api__message__SignalMessage_sender_ratchet_key;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__message__SignalMessage_serialize(that) {
        const ret = wasm.wire__crate__api__message__SignalMessage_serialize(that);
        return ret;
    }
    exports.wire__crate__api__message__SignalMessage_serialize = wire__crate__api__message__SignalMessage_serialize;

    /**
     * @param {any} that
     * @param {string} sender_address_name
     * @param {number} sender_address_device_id
     * @param {string} recipient_address_name
     * @param {number} recipient_address_device_id
     * @param {Uint8Array} sender_identity_key
     * @param {Uint8Array} receiver_identity_key
     * @param {Uint8Array} mac_key
     * @returns {any}
     */
    function wire__crate__api__message__SignalMessage_verify_mac(that, sender_address_name, sender_address_device_id, recipient_address_name, recipient_address_device_id, sender_identity_key, receiver_identity_key, mac_key) {
        const ptr0 = passStringToWasm0(sender_address_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(recipient_address_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        const ptr2 = passArray8ToWasm0(sender_identity_key, wasm.__wbindgen_malloc);
        const len2 = WASM_VECTOR_LEN;
        const ptr3 = passArray8ToWasm0(receiver_identity_key, wasm.__wbindgen_malloc);
        const len3 = WASM_VECTOR_LEN;
        const ptr4 = passArray8ToWasm0(mac_key, wasm.__wbindgen_malloc);
        const len4 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__message__SignalMessage_verify_mac(that, ptr0, len0, sender_address_device_id, ptr1, len1, recipient_address_device_id, ptr2, len2, ptr3, len3, ptr4, len4);
        return ret;
    }
    exports.wire__crate__api__message__SignalMessage_verify_mac = wire__crate__api__message__SignalMessage_verify_mac;

    /**
     * @param {Uint8Array} bytes
     * @returns {any}
     */
    function wire__crate__api__prekey__PreKeyRecord_deserialize(bytes) {
        const ptr0 = passArray8ToWasm0(bytes, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__prekey__PreKeyRecord_deserialize(ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__prekey__PreKeyRecord_deserialize = wire__crate__api__prekey__PreKeyRecord_deserialize;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__prekey__PreKeyRecord_id(that) {
        const ret = wasm.wire__crate__api__prekey__PreKeyRecord_id(that);
        return ret;
    }
    exports.wire__crate__api__prekey__PreKeyRecord_id = wire__crate__api__prekey__PreKeyRecord_id;

    /**
     * @param {number} id
     * @param {any} public_key
     * @param {any} private_key
     * @returns {any}
     */
    function wire__crate__api__prekey__PreKeyRecord_new(id, public_key, private_key) {
        const ret = wasm.wire__crate__api__prekey__PreKeyRecord_new(id, public_key, private_key);
        return ret;
    }
    exports.wire__crate__api__prekey__PreKeyRecord_new = wire__crate__api__prekey__PreKeyRecord_new;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__prekey__PreKeyRecord_private_key(that) {
        const ret = wasm.wire__crate__api__prekey__PreKeyRecord_private_key(that);
        return ret;
    }
    exports.wire__crate__api__prekey__PreKeyRecord_private_key = wire__crate__api__prekey__PreKeyRecord_private_key;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__prekey__PreKeyRecord_public_key(that) {
        const ret = wasm.wire__crate__api__prekey__PreKeyRecord_public_key(that);
        return ret;
    }
    exports.wire__crate__api__prekey__PreKeyRecord_public_key = wire__crate__api__prekey__PreKeyRecord_public_key;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__prekey__PreKeyRecord_serialize(that) {
        const ret = wasm.wire__crate__api__prekey__PreKeyRecord_serialize(that);
        return ret;
    }
    exports.wire__crate__api__prekey__PreKeyRecord_serialize = wire__crate__api__prekey__PreKeyRecord_serialize;

    /**
     * @param {string} sender_uuid
     * @param {number} sender_device_id
     * @param {Uint8Array} sender_identity_key
     * @param {any} expiration
     * @param {Uint8Array} server_certificate
     * @param {Uint8Array} server_private_key
     * @returns {any}
     */
    function wire__crate__api__sealed_sender__create_sender_certificate(sender_uuid, sender_device_id, sender_identity_key, expiration, server_certificate, server_private_key) {
        const ptr0 = passStringToWasm0(sender_uuid, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passArray8ToWasm0(sender_identity_key, wasm.__wbindgen_malloc);
        const len1 = WASM_VECTOR_LEN;
        const ptr2 = passArray8ToWasm0(server_certificate, wasm.__wbindgen_malloc);
        const len2 = WASM_VECTOR_LEN;
        const ptr3 = passArray8ToWasm0(server_private_key, wasm.__wbindgen_malloc);
        const len3 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__sealed_sender__create_sender_certificate(ptr0, len0, sender_device_id, ptr1, len1, expiration, ptr2, len2, ptr3, len3);
        return ret;
    }
    exports.wire__crate__api__sealed_sender__create_sender_certificate = wire__crate__api__sealed_sender__create_sender_certificate;

    /**
     * @param {number} key_id
     * @param {Uint8Array} server_public_key
     * @param {Uint8Array} trust_root_private_key
     * @returns {any}
     */
    function wire__crate__api__sealed_sender__create_server_certificate(key_id, server_public_key, trust_root_private_key) {
        const ptr0 = passArray8ToWasm0(server_public_key, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passArray8ToWasm0(trust_root_private_key, wasm.__wbindgen_malloc);
        const len1 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__sealed_sender__create_server_certificate(key_id, ptr0, len0, ptr1, len1);
        return ret;
    }
    exports.wire__crate__api__sealed_sender__create_server_certificate = wire__crate__api__sealed_sender__create_server_certificate;

    /**
     * @param {any} port_
     * @param {Uint8Array} ciphertext
     * @param {Uint8Array} trust_root
     * @param {any} timestamp
     * @param {string} local_name
     * @param {number} local_device_id
     * @param {any} load_session
     * @param {any} store_session
     * @param {any} get_identity_key_pair
     * @param {any} get_local_registration_id
     * @param {any} save_identity
     * @param {any} load_signed_pre_key
     * @param {any} load_pre_key
     * @param {any} remove_pre_key
     * @param {any} load_kyber_pre_key
     * @param {any} mark_kyber_pre_key_used
     * @param {any} get_identity
     */
    function wire__crate__api__sealed_sender__sealed_sender_decrypt_with_callbacks(port_, ciphertext, trust_root, timestamp, local_name, local_device_id, load_session, store_session, get_identity_key_pair, get_local_registration_id, save_identity, load_signed_pre_key, load_pre_key, remove_pre_key, load_kyber_pre_key, mark_kyber_pre_key_used, get_identity) {
        const ptr0 = passArray8ToWasm0(ciphertext, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passArray8ToWasm0(trust_root, wasm.__wbindgen_malloc);
        const len1 = WASM_VECTOR_LEN;
        const ptr2 = passStringToWasm0(local_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len2 = WASM_VECTOR_LEN;
        wasm.wire__crate__api__sealed_sender__sealed_sender_decrypt_with_callbacks(port_, ptr0, len0, ptr1, len1, timestamp, ptr2, len2, local_device_id, load_session, store_session, get_identity_key_pair, get_local_registration_id, save_identity, load_signed_pre_key, load_pre_key, remove_pre_key, load_kyber_pre_key, mark_kyber_pre_key_used, get_identity);
    }
    exports.wire__crate__api__sealed_sender__sealed_sender_decrypt_with_callbacks = wire__crate__api__sealed_sender__sealed_sender_decrypt_with_callbacks;

    /**
     * @param {any} port_
     * @param {string} recipient_name
     * @param {number} recipient_device_id
     * @param {Uint8Array} plaintext
     * @param {Uint8Array} sender_certificate
     * @param {any} load_session
     * @param {any} store_session
     * @param {any} get_identity_key_pair
     * @param {any} get_local_registration_id
     * @param {any} get_identity
     */
    function wire__crate__api__sealed_sender__sealed_sender_encrypt_with_callbacks(port_, recipient_name, recipient_device_id, plaintext, sender_certificate, load_session, store_session, get_identity_key_pair, get_local_registration_id, get_identity) {
        const ptr0 = passStringToWasm0(recipient_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passArray8ToWasm0(plaintext, wasm.__wbindgen_malloc);
        const len1 = WASM_VECTOR_LEN;
        const ptr2 = passArray8ToWasm0(sender_certificate, wasm.__wbindgen_malloc);
        const len2 = WASM_VECTOR_LEN;
        wasm.wire__crate__api__sealed_sender__sealed_sender_encrypt_with_callbacks(port_, ptr0, len0, recipient_device_id, ptr1, len1, ptr2, len2, load_session, store_session, get_identity_key_pair, get_local_registration_id, get_identity);
    }
    exports.wire__crate__api__sealed_sender__sealed_sender_encrypt_with_callbacks = wire__crate__api__sealed_sender__sealed_sender_encrypt_with_callbacks;

    /**
     * @param {Uint8Array} certificate
     * @returns {any}
     */
    function wire__crate__api__sealed_sender__sender_certificate_get_expiration(certificate) {
        const ptr0 = passArray8ToWasm0(certificate, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__sealed_sender__sender_certificate_get_expiration(ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__sealed_sender__sender_certificate_get_expiration = wire__crate__api__sealed_sender__sender_certificate_get_expiration;

    /**
     * @param {Uint8Array} certificate
     * @returns {any}
     */
    function wire__crate__api__sealed_sender__sender_certificate_get_key(certificate) {
        const ptr0 = passArray8ToWasm0(certificate, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__sealed_sender__sender_certificate_get_key(ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__sealed_sender__sender_certificate_get_key = wire__crate__api__sealed_sender__sender_certificate_get_key;

    /**
     * @param {Uint8Array} certificate
     * @returns {any}
     */
    function wire__crate__api__sealed_sender__sender_certificate_get_sender_device_id(certificate) {
        const ptr0 = passArray8ToWasm0(certificate, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__sealed_sender__sender_certificate_get_sender_device_id(ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__sealed_sender__sender_certificate_get_sender_device_id = wire__crate__api__sealed_sender__sender_certificate_get_sender_device_id;

    /**
     * @param {Uint8Array} certificate
     * @returns {any}
     */
    function wire__crate__api__sealed_sender__sender_certificate_get_sender_name(certificate) {
        const ptr0 = passArray8ToWasm0(certificate, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__sealed_sender__sender_certificate_get_sender_name(ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__sealed_sender__sender_certificate_get_sender_name = wire__crate__api__sealed_sender__sender_certificate_get_sender_name;

    /**
     * @param {Uint8Array} certificate
     * @param {Uint8Array} trust_root
     * @param {any} timestamp
     * @returns {any}
     */
    function wire__crate__api__sealed_sender__validate_sender_certificate(certificate, trust_root, timestamp) {
        const ptr0 = passArray8ToWasm0(certificate, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passArray8ToWasm0(trust_root, wasm.__wbindgen_malloc);
        const len1 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__sealed_sender__validate_sender_certificate(ptr0, len0, ptr1, len1, timestamp);
        return ret;
    }
    exports.wire__crate__api__sealed_sender__validate_sender_certificate = wire__crate__api__sealed_sender__validate_sender_certificate;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__session__SessionRecord_archive_current_state(that) {
        const ret = wasm.wire__crate__api__session__SessionRecord_archive_current_state(that);
        return ret;
    }
    exports.wire__crate__api__session__SessionRecord_archive_current_state = wire__crate__api__session__SessionRecord_archive_current_state;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__session__SessionRecord_clone_record(that) {
        const ret = wasm.wire__crate__api__session__SessionRecord_clone_record(that);
        return ret;
    }
    exports.wire__crate__api__session__SessionRecord_clone_record = wire__crate__api__session__SessionRecord_clone_record;

    /**
     * @param {any} that
     * @param {any} key
     * @returns {any}
     */
    function wire__crate__api__session__SessionRecord_current_ratchet_key_matches(that, key) {
        const ret = wasm.wire__crate__api__session__SessionRecord_current_ratchet_key_matches(that, key);
        return ret;
    }
    exports.wire__crate__api__session__SessionRecord_current_ratchet_key_matches = wire__crate__api__session__SessionRecord_current_ratchet_key_matches;

    /**
     * @param {Uint8Array} bytes
     * @returns {any}
     */
    function wire__crate__api__session__SessionRecord_deserialize(bytes) {
        const ptr0 = passArray8ToWasm0(bytes, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__session__SessionRecord_deserialize(ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__session__SessionRecord_deserialize = wire__crate__api__session__SessionRecord_deserialize;

    /**
     * @param {any} that
     * @param {any} now_millis
     * @returns {any}
     */
    function wire__crate__api__session__SessionRecord_has_usable_sender_chain(that, now_millis) {
        const ret = wasm.wire__crate__api__session__SessionRecord_has_usable_sender_chain(that, now_millis);
        return ret;
    }
    exports.wire__crate__api__session__SessionRecord_has_usable_sender_chain = wire__crate__api__session__SessionRecord_has_usable_sender_chain;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__session__SessionRecord_local_registration_id(that) {
        const ret = wasm.wire__crate__api__session__SessionRecord_local_registration_id(that);
        return ret;
    }
    exports.wire__crate__api__session__SessionRecord_local_registration_id = wire__crate__api__session__SessionRecord_local_registration_id;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__session__SessionRecord_remote_registration_id(that) {
        const ret = wasm.wire__crate__api__session__SessionRecord_remote_registration_id(that);
        return ret;
    }
    exports.wire__crate__api__session__SessionRecord_remote_registration_id = wire__crate__api__session__SessionRecord_remote_registration_id;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__session__SessionRecord_serialize(that) {
        const ret = wasm.wire__crate__api__session__SessionRecord_serialize(that);
        return ret;
    }
    exports.wire__crate__api__session__SessionRecord_serialize = wire__crate__api__session__SessionRecord_serialize;

    /**
     * @param {any} port_
     * @param {string} remote_name
     * @param {number} remote_device_id
     * @param {string} local_name
     * @param {number} local_device_id
     * @param {any} bundle
     * @param {any} load_session
     * @param {any} store_session
     * @param {any} get_identity_key_pair
     * @param {any} get_local_registration_id
     * @param {any} save_identity
     * @param {any} get_identity
     */
    function wire__crate__api__session_builder__process_prekey_bundle_with_callbacks(port_, remote_name, remote_device_id, local_name, local_device_id, bundle, load_session, store_session, get_identity_key_pair, get_local_registration_id, save_identity, get_identity) {
        const ptr0 = passStringToWasm0(remote_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(local_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        wasm.wire__crate__api__session_builder__process_prekey_bundle_with_callbacks(port_, ptr0, len0, remote_device_id, ptr1, len1, local_device_id, bundle, load_session, store_session, get_identity_key_pair, get_local_registration_id, save_identity, get_identity);
    }
    exports.wire__crate__api__session_builder__process_prekey_bundle_with_callbacks = wire__crate__api__session_builder__process_prekey_bundle_with_callbacks;

    /**
     * @param {Uint8Array} message
     * @returns {any}
     */
    function wire__crate__api__session_cipher__extract_prekey_message_ids(message) {
        const ptr0 = passArray8ToWasm0(message, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__session_cipher__extract_prekey_message_ids(ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__session_cipher__extract_prekey_message_ids = wire__crate__api__session_cipher__extract_prekey_message_ids;

    /**
     * @param {any} port_
     * @param {string} remote_name
     * @param {number} remote_device_id
     * @param {string} local_name
     * @param {number} local_device_id
     * @param {Uint8Array} ciphertext
     * @param {any} load_session
     * @param {any} store_session
     * @param {any} get_identity_key_pair
     * @param {any} get_local_registration_id
     * @param {any} save_identity
     * @param {any} load_signed_pre_key
     * @param {any} load_pre_key
     * @param {any} remove_pre_key
     * @param {any} load_kyber_pre_key
     * @param {any} mark_kyber_pre_key_used
     * @param {any} get_identity
     */
    function wire__crate__api__session_cipher__message_decrypt_prekey_with_callbacks(port_, remote_name, remote_device_id, local_name, local_device_id, ciphertext, load_session, store_session, get_identity_key_pair, get_local_registration_id, save_identity, load_signed_pre_key, load_pre_key, remove_pre_key, load_kyber_pre_key, mark_kyber_pre_key_used, get_identity) {
        const ptr0 = passStringToWasm0(remote_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(local_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        const ptr2 = passArray8ToWasm0(ciphertext, wasm.__wbindgen_malloc);
        const len2 = WASM_VECTOR_LEN;
        wasm.wire__crate__api__session_cipher__message_decrypt_prekey_with_callbacks(port_, ptr0, len0, remote_device_id, ptr1, len1, local_device_id, ptr2, len2, load_session, store_session, get_identity_key_pair, get_local_registration_id, save_identity, load_signed_pre_key, load_pre_key, remove_pre_key, load_kyber_pre_key, mark_kyber_pre_key_used, get_identity);
    }
    exports.wire__crate__api__session_cipher__message_decrypt_prekey_with_callbacks = wire__crate__api__session_cipher__message_decrypt_prekey_with_callbacks;

    /**
     * @param {any} port_
     * @param {string} remote_name
     * @param {number} remote_device_id
     * @param {string} local_name
     * @param {number} local_device_id
     * @param {Uint8Array} ciphertext
     * @param {any} load_session
     * @param {any} store_session
     * @param {any} get_identity_key_pair
     * @param {any} get_local_registration_id
     * @param {any} save_identity
     * @param {any} get_identity
     */
    function wire__crate__api__session_cipher__message_decrypt_signal_with_callbacks(port_, remote_name, remote_device_id, local_name, local_device_id, ciphertext, load_session, store_session, get_identity_key_pair, get_local_registration_id, save_identity, get_identity) {
        const ptr0 = passStringToWasm0(remote_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(local_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        const ptr2 = passArray8ToWasm0(ciphertext, wasm.__wbindgen_malloc);
        const len2 = WASM_VECTOR_LEN;
        wasm.wire__crate__api__session_cipher__message_decrypt_signal_with_callbacks(port_, ptr0, len0, remote_device_id, ptr1, len1, local_device_id, ptr2, len2, load_session, store_session, get_identity_key_pair, get_local_registration_id, save_identity, get_identity);
    }
    exports.wire__crate__api__session_cipher__message_decrypt_signal_with_callbacks = wire__crate__api__session_cipher__message_decrypt_signal_with_callbacks;

    /**
     * @param {any} port_
     * @param {string} remote_name
     * @param {number} remote_device_id
     * @param {string} local_name
     * @param {number} local_device_id
     * @param {Uint8Array} plaintext
     * @param {any} load_session
     * @param {any} store_session
     * @param {any} get_identity_key_pair
     * @param {any} get_local_registration_id
     * @param {any} get_identity
     */
    function wire__crate__api__session_cipher__message_encrypt_with_callbacks(port_, remote_name, remote_device_id, local_name, local_device_id, plaintext, load_session, store_session, get_identity_key_pair, get_local_registration_id, get_identity) {
        const ptr0 = passStringToWasm0(remote_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(local_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        const ptr2 = passArray8ToWasm0(plaintext, wasm.__wbindgen_malloc);
        const len2 = WASM_VECTOR_LEN;
        wasm.wire__crate__api__session_cipher__message_encrypt_with_callbacks(port_, ptr0, len0, remote_device_id, ptr1, len1, local_device_id, ptr2, len2, load_session, store_session, get_identity_key_pair, get_local_registration_id, get_identity);
    }
    exports.wire__crate__api__session_cipher__message_encrypt_with_callbacks = wire__crate__api__session_cipher__message_encrypt_with_callbacks;

    /**
     * @param {Uint8Array} bytes
     * @returns {any}
     */
    function wire__crate__api__signed_prekey__SignedPreKeyRecord_deserialize(bytes) {
        const ptr0 = passArray8ToWasm0(bytes, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__signed_prekey__SignedPreKeyRecord_deserialize(ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__signed_prekey__SignedPreKeyRecord_deserialize = wire__crate__api__signed_prekey__SignedPreKeyRecord_deserialize;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__signed_prekey__SignedPreKeyRecord_id(that) {
        const ret = wasm.wire__crate__api__signed_prekey__SignedPreKeyRecord_id(that);
        return ret;
    }
    exports.wire__crate__api__signed_prekey__SignedPreKeyRecord_id = wire__crate__api__signed_prekey__SignedPreKeyRecord_id;

    /**
     * @param {number} id
     * @param {any} timestamp
     * @param {any} public_key
     * @param {any} private_key
     * @param {Uint8Array} signature
     * @returns {any}
     */
    function wire__crate__api__signed_prekey__SignedPreKeyRecord_new(id, timestamp, public_key, private_key, signature) {
        const ptr0 = passArray8ToWasm0(signature, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.wire__crate__api__signed_prekey__SignedPreKeyRecord_new(id, timestamp, public_key, private_key, ptr0, len0);
        return ret;
    }
    exports.wire__crate__api__signed_prekey__SignedPreKeyRecord_new = wire__crate__api__signed_prekey__SignedPreKeyRecord_new;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__signed_prekey__SignedPreKeyRecord_private_key(that) {
        const ret = wasm.wire__crate__api__signed_prekey__SignedPreKeyRecord_private_key(that);
        return ret;
    }
    exports.wire__crate__api__signed_prekey__SignedPreKeyRecord_private_key = wire__crate__api__signed_prekey__SignedPreKeyRecord_private_key;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__signed_prekey__SignedPreKeyRecord_public_key(that) {
        const ret = wasm.wire__crate__api__signed_prekey__SignedPreKeyRecord_public_key(that);
        return ret;
    }
    exports.wire__crate__api__signed_prekey__SignedPreKeyRecord_public_key = wire__crate__api__signed_prekey__SignedPreKeyRecord_public_key;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__signed_prekey__SignedPreKeyRecord_serialize(that) {
        const ret = wasm.wire__crate__api__signed_prekey__SignedPreKeyRecord_serialize(that);
        return ret;
    }
    exports.wire__crate__api__signed_prekey__SignedPreKeyRecord_serialize = wire__crate__api__signed_prekey__SignedPreKeyRecord_serialize;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__signed_prekey__SignedPreKeyRecord_signature(that) {
        const ret = wasm.wire__crate__api__signed_prekey__SignedPreKeyRecord_signature(that);
        return ret;
    }
    exports.wire__crate__api__signed_prekey__SignedPreKeyRecord_signature = wire__crate__api__signed_prekey__SignedPreKeyRecord_signature;

    /**
     * @param {any} that
     * @returns {any}
     */
    function wire__crate__api__signed_prekey__SignedPreKeyRecord_timestamp(that) {
        const ret = wasm.wire__crate__api__signed_prekey__SignedPreKeyRecord_timestamp(that);
        return ret;
    }
    exports.wire__crate__api__signed_prekey__SignedPreKeyRecord_timestamp = wire__crate__api__signed_prekey__SignedPreKeyRecord_timestamp;
    function __wbg_get_imports() {
        const import0 = {
            __proto__: null,
            __wbg_Number_9a4e0ecb0fa16705: function(arg0) {
                const ret = Number(arg0);
                return ret;
            },
            __wbg___wbindgen_bigint_get_as_i64_d968e41184ae354f: function(arg0, arg1) {
                const v = arg1;
                const ret = typeof(v) === 'bigint' ? v : undefined;
                getDataViewMemory0().setBigInt64(arg0 + 8 * 1, isLikeNone(ret) ? BigInt(0) : ret, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, !isLikeNone(ret), true);
            },
            __wbg___wbindgen_debug_string_c25d447a39f5578f: function(arg0, arg1) {
                const ret = debugString(arg1);
                const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
                const len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            },
            __wbg___wbindgen_is_function_1ff95bcc5517c252: function(arg0) {
                const ret = typeof(arg0) === 'function';
                return ret;
            },
            __wbg___wbindgen_is_null_ea9085d691f535d3: function(arg0) {
                const ret = arg0 === null;
                return ret;
            },
            __wbg___wbindgen_is_undefined_c05833b95a3cf397: function(arg0) {
                const ret = arg0 === undefined;
                return ret;
            },
            __wbg___wbindgen_jsval_eq_e659fcf7b0e32763: function(arg0, arg1) {
                const ret = arg0 === arg1;
                return ret;
            },
            __wbg___wbindgen_memory_de265df8aadd6273: function() {
                const ret = wasm.memory;
                return ret;
            },
            __wbg___wbindgen_module_a22faa8909381977: function() {
                const ret = wasmModule;
                return ret;
            },
            __wbg___wbindgen_number_get_394265ed1e1b84ee: function(arg0, arg1) {
                const obj = arg1;
                const ret = typeof(obj) === 'number' ? obj : undefined;
                getDataViewMemory0().setFloat64(arg0 + 8 * 1, isLikeNone(ret) ? 0 : ret, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, !isLikeNone(ret), true);
            },
            __wbg___wbindgen_string_get_b0ca35b86a603356: function(arg0, arg1) {
                const obj = arg1;
                const ret = typeof(obj) === 'string' ? obj : undefined;
                var ptr1 = isLikeNone(ret) ? 0 : passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
                var len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            },
            __wbg___wbindgen_throw_344f42d3211c4765: function(arg0, arg1) {
                throw new Error(getStringFromWasm0(arg0, arg1));
            },
            __wbg__wbg_cb_unref_fffb441def202758: function(arg0) {
                arg0._wbg_cb_unref();
            },
            __wbg_createObjectURL_416e527781e6fd6d: function() { return handleError(function (arg0, arg1) {
                const ret = URL.createObjectURL(arg1);
                const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
                const len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            }, arguments); },
            __wbg_data_328de4280640da92: function(arg0) {
                const ret = arg0.data;
                return ret;
            },
            __wbg_error_7bfe3b7ebaaa5936: function(arg0, arg1) {
                console.error(getStringFromWasm0(arg0, arg1));
            },
            __wbg_error_a6fa202b58aa1cd3: function(arg0, arg1) {
                let deferred0_0;
                let deferred0_1;
                try {
                    deferred0_0 = arg0;
                    deferred0_1 = arg1;
                    console.error(getStringFromWasm0(arg0, arg1));
                } finally {
                    wasm.__wbindgen_free(deferred0_0, deferred0_1, 1);
                }
            },
            __wbg_eval_832ed6e42a9be51c: function() { return handleError(function (arg0, arg1) {
                const ret = eval(getStringFromWasm0(arg0, arg1));
                return ret;
            }, arguments); },
            __wbg_getRandomValues_3f44b700395062e5: function() { return handleError(function (arg0, arg1) {
                globalThis.crypto.getRandomValues(getArrayU8FromWasm0(arg0, arg1));
            }, arguments); },
            __wbg_get_78f252d074a84d0b: function() { return handleError(function (arg0, arg1) {
                const ret = Reflect.get(arg0, arg1);
                return ret;
            }, arguments); },
            __wbg_instanceof_BroadcastChannel_e5369d10d0f4e710: function(arg0) {
                let result;
                try {
                    result = arg0 instanceof BroadcastChannel;
                } catch (_) {
                    result = false;
                }
                const ret = result;
                return ret;
            },
            __wbg_instanceof_ErrorEvent_bf6884e010b19bde: function(arg0) {
                let result;
                try {
                    result = arg0 instanceof ErrorEvent;
                } catch (_) {
                    result = false;
                }
                const ret = result;
                return ret;
            },
            __wbg_instanceof_MessageEvent_7d226bddd45cb41d: function(arg0) {
                let result;
                try {
                    result = arg0 instanceof MessageEvent;
                } catch (_) {
                    result = false;
                }
                const ret = result;
                return ret;
            },
            __wbg_length_1f0964f4a5e2c6d8: function(arg0) {
                const ret = arg0.length;
                return ret;
            },
            __wbg_message_f959e4f25c384966: function(arg0, arg1) {
                const ret = arg1.message;
                const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
                const len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            },
            __wbg_name_ff558fda9c02e53e: function(arg0, arg1) {
                const ret = arg1.name;
                const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
                const len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            },
            __wbg_new_227d7c05414eb861: function() {
                const ret = new Error();
                return ret;
            },
            __wbg_new_245322ac8cd2a4ae: function() { return handleError(function (arg0, arg1) {
                const ret = new BroadcastChannel(getStringFromWasm0(arg0, arg1));
                return ret;
            }, arguments); },
            __wbg_new_32b398fb48b6d94a: function() {
                const ret = new Array();
                return ret;
            },
            __wbg_new_8f0c2d11e48a4727: function() { return handleError(function (arg0, arg1) {
                const ret = new Worker(getStringFromWasm0(arg0, arg1));
                return ret;
            }, arguments); },
            __wbg_new_cd45aabdf6073e84: function(arg0) {
                const ret = new Uint8Array(arg0);
                return ret;
            },
            __wbg_new_da52cf8fe3429cb2: function() {
                const ret = new Object();
                return ret;
            },
            __wbg_new_from_slice_77cdfb7977362f3c: function(arg0, arg1) {
                const ret = new Uint8Array(getArrayU8FromWasm0(arg0, arg1));
                return ret;
            },
            __wbg_new_with_blob_sequence_and_options_7de925fc93f05582: function() { return handleError(function (arg0, arg1) {
                const ret = new Blob(arg0, arg1);
                return ret;
            }, arguments); },
            __wbg_now_86c0d4ba3fa605b8: function() {
                const ret = Date.now();
                return ret;
            },
            __wbg_postMessage_56396682c54d5757: function() { return handleError(function (arg0, arg1) {
                arg0.postMessage(arg1);
            }, arguments); },
            __wbg_postMessage_59736484efc322cf: function() { return handleError(function (arg0, arg1) {
                arg0.postMessage(arg1);
            }, arguments); },
            __wbg_postMessage_ea8632bb43026d6a: function() { return handleError(function (arg0, arg1) {
                arg0.postMessage(arg1);
            }, arguments); },
            __wbg_prototypesetcall_4770620bbe4688a0: function(arg0, arg1, arg2) {
                Uint8Array.prototype.set.call(getArrayU8FromWasm0(arg0, arg1), arg2);
            },
            __wbg_push_d2ae3af0c1217ae6: function(arg0, arg1) {
                const ret = arg0.push(arg1);
                return ret;
            },
            __wbg_queueMicrotask_0ab5b2d2393e99b9: function(arg0) {
                const ret = arg0.queueMicrotask;
                return ret;
            },
            __wbg_queueMicrotask_6a09b7bc46549209: function(arg0) {
                queueMicrotask(arg0);
            },
            __wbg_resolve_2191a4dfe481c25b: function(arg0) {
                const ret = Promise.resolve(arg0);
                return ret;
            },
            __wbg_set_8535240470bf2500: function() { return handleError(function (arg0, arg1, arg2) {
                const ret = Reflect.set(arg0, arg1, arg2);
                return ret;
            }, arguments); },
            __wbg_set_onerror_cc3a477eed014488: function(arg0, arg1) {
                arg0.onerror = arg1;
            },
            __wbg_set_onmessage_57d6a01ac0bfd3a3: function(arg0, arg1) {
                arg0.onmessage = arg1;
            },
            __wbg_set_type_8ce203e412e28cf6: function(arg0, arg1, arg2) {
                arg0.type = getStringFromWasm0(arg1, arg2);
            },
            __wbg_stack_3b0d974bbf31e44f: function(arg0, arg1) {
                const ret = arg1.stack;
                const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
                const len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            },
            __wbg_static_accessor_GLOBAL_4ef717fb391d88b7: function() {
                const ret = typeof global === 'undefined' ? null : global;
                return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
            },
            __wbg_static_accessor_GLOBAL_THIS_8d1badc68b5a74f4: function() {
                const ret = typeof globalThis === 'undefined' ? null : globalThis;
                return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
            },
            __wbg_static_accessor_SELF_146583524fe1469b: function() {
                const ret = typeof self === 'undefined' ? null : self;
                return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
            },
            __wbg_static_accessor_WINDOW_f2829a2234d7819e: function() {
                const ret = typeof window === 'undefined' ? null : window;
                return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
            },
            __wbg_then_6ec10ae38b3e92f7: function(arg0, arg1) {
                const ret = arg0.then(arg1);
                return ret;
            },
            __wbindgen_cast_0000000000000001: function(arg0, arg1) {
                // Cast intrinsic for `Closure(Closure { owned: true, function: Function { arguments: [Externref], shim_idx: 425, ret: Result(Unit), inner_ret: Some(Result(Unit)) }, mutable: true }) -> Externref`.
                const ret = makeMutClosure(arg0, arg1, wasm_bindgen_32850284572519d5___convert__closures_____invoke___wasm_bindgen_32850284572519d5___JsValue__core_9b3796e30d99ddb7___result__Result_____wasm_bindgen_32850284572519d5___JsError___true_);
                return ret;
            },
            __wbindgen_cast_0000000000000002: function(arg0, arg1) {
                // Cast intrinsic for `Closure(Closure { owned: true, function: Function { arguments: [NamedExternref("Event")], shim_idx: 351, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
                const ret = makeMutClosure(arg0, arg1, wasm_bindgen_32850284572519d5___convert__closures_____invoke___web_sys_263d4ad0bcf2ad1e___features__gen_MessageEvent__MessageEvent______true_);
                return ret;
            },
            __wbindgen_cast_0000000000000003: function(arg0) {
                // Cast intrinsic for `F64 -> Externref`.
                const ret = arg0;
                return ret;
            },
            __wbindgen_cast_0000000000000004: function(arg0, arg1) {
                // Cast intrinsic for `Ref(String) -> Externref`.
                const ret = getStringFromWasm0(arg0, arg1);
                return ret;
            },
            __wbindgen_cast_0000000000000005: function(arg0) {
                // Cast intrinsic for `U64 -> Externref`.
                const ret = BigInt.asUintN(64, arg0);
                return ret;
            },
            __wbindgen_init_externref_table: function() {
                const table = wasm.__wbindgen_externrefs;
                const offset = table.grow(4);
                table.set(0, undefined);
                table.set(offset + 0, undefined);
                table.set(offset + 1, null);
                table.set(offset + 2, true);
                table.set(offset + 3, false);
            },
        };
        return {
            __proto__: null,
            "./libsignal_frb_bg.js": import0,
        };
    }

    function wasm_bindgen_32850284572519d5___convert__closures_____invoke___web_sys_263d4ad0bcf2ad1e___features__gen_MessageEvent__MessageEvent______true_(arg0, arg1, arg2) {
        wasm.wasm_bindgen_32850284572519d5___convert__closures_____invoke___web_sys_263d4ad0bcf2ad1e___features__gen_MessageEvent__MessageEvent______true_(arg0, arg1, arg2);
    }

    function wasm_bindgen_32850284572519d5___convert__closures_____invoke___wasm_bindgen_32850284572519d5___JsValue__core_9b3796e30d99ddb7___result__Result_____wasm_bindgen_32850284572519d5___JsError___true_(arg0, arg1, arg2) {
        const ret = wasm.wasm_bindgen_32850284572519d5___convert__closures_____invoke___wasm_bindgen_32850284572519d5___JsValue__core_9b3796e30d99ddb7___result__Result_____wasm_bindgen_32850284572519d5___JsError___true_(arg0, arg1, arg2);
        if (ret[1]) {
            throw takeFromExternrefTable0(ret[0]);
        }
    }

    const WorkerPoolFinalization = (typeof FinalizationRegistry === 'undefined')
        ? { register: () => {}, unregister: () => {} }
        : new FinalizationRegistry(ptr => wasm.__wbg_workerpool_free(ptr, 1));

    function addToExternrefTable0(obj) {
        const idx = wasm.__externref_table_alloc();
        wasm.__wbindgen_externrefs.set(idx, obj);
        return idx;
    }

    const CLOSURE_DTORS = (typeof FinalizationRegistry === 'undefined')
        ? { register: () => {}, unregister: () => {} }
        : new FinalizationRegistry(state => wasm.__wbindgen_destroy_closure(state.a, state.b));

    function debugString(val) {
        // primitive types
        const type = typeof val;
        if (type == 'number' || type == 'boolean' || val == null) {
            return  `${val}`;
        }
        if (type == 'string') {
            return `"${val}"`;
        }
        if (type == 'symbol') {
            const description = val.description;
            if (description == null) {
                return 'Symbol';
            } else {
                return `Symbol(${description})`;
            }
        }
        if (type == 'function') {
            const name = val.name;
            if (typeof name == 'string' && name.length > 0) {
                return `Function(${name})`;
            } else {
                return 'Function';
            }
        }
        // objects
        if (Array.isArray(val)) {
            const length = val.length;
            let debug = '[';
            if (length > 0) {
                debug += debugString(val[0]);
            }
            for(let i = 1; i < length; i++) {
                debug += ', ' + debugString(val[i]);
            }
            debug += ']';
            return debug;
        }
        // Test for built-in
        const builtInMatches = /\[object ([^\]]+)\]/.exec(toString.call(val));
        let className;
        if (builtInMatches && builtInMatches.length > 1) {
            className = builtInMatches[1];
        } else {
            // Failed to match the standard '[object ClassName]'
            return toString.call(val);
        }
        if (className == 'Object') {
            // we're a user defined class or Object
            // JSON.stringify avoids problems with cycles, and is generally much
            // easier than looping through ownProperties of `val`.
            try {
                return 'Object(' + JSON.stringify(val) + ')';
            } catch (_) {
                return 'Object';
            }
        }
        // errors
        if (val instanceof Error) {
            return `${val.name}: ${val.message}\n${val.stack}`;
        }
        // TODO we could test for more things here, like `Set`s and `Map`s.
        return className;
    }

    function getArrayU8FromWasm0(ptr, len) {
        ptr = ptr >>> 0;
        return getUint8ArrayMemory0().subarray(ptr / 1, ptr / 1 + len);
    }

    let cachedDataViewMemory0 = null;
    function getDataViewMemory0() {
        if (cachedDataViewMemory0 === null || cachedDataViewMemory0.buffer.detached === true || (cachedDataViewMemory0.buffer.detached === undefined && cachedDataViewMemory0.buffer !== wasm.memory.buffer)) {
            cachedDataViewMemory0 = new DataView(wasm.memory.buffer);
        }
        return cachedDataViewMemory0;
    }

    function getStringFromWasm0(ptr, len) {
        return decodeText(ptr >>> 0, len);
    }

    let cachedUint8ArrayMemory0 = null;
    function getUint8ArrayMemory0() {
        if (cachedUint8ArrayMemory0 === null || cachedUint8ArrayMemory0.byteLength === 0) {
            cachedUint8ArrayMemory0 = new Uint8Array(wasm.memory.buffer);
        }
        return cachedUint8ArrayMemory0;
    }

    function handleError(f, args) {
        try {
            return f.apply(this, args);
        } catch (e) {
            const idx = addToExternrefTable0(e);
            wasm.__wbindgen_exn_store(idx);
        }
    }

    function isLikeNone(x) {
        return x === undefined || x === null;
    }

    function makeMutClosure(arg0, arg1, f) {
        const state = { a: arg0, b: arg1, cnt: 1 };
        const real = (...args) => {

            // First up with a closure we increment the internal reference
            // count. This ensures that the Rust closure environment won't
            // be deallocated while we're invoking it.
            state.cnt++;
            const a = state.a;
            state.a = 0;
            try {
                return f(a, state.b, ...args);
            } finally {
                state.a = a;
                real._wbg_cb_unref();
            }
        };
        real._wbg_cb_unref = () => {
            if (--state.cnt === 0) {
                wasm.__wbindgen_destroy_closure(state.a, state.b);
                state.a = 0;
                CLOSURE_DTORS.unregister(state);
            }
        };
        CLOSURE_DTORS.register(real, state, state);
        return real;
    }

    function passArray8ToWasm0(arg, malloc) {
        const ptr = malloc(arg.length * 1, 1) >>> 0;
        getUint8ArrayMemory0().set(arg, ptr / 1);
        WASM_VECTOR_LEN = arg.length;
        return ptr;
    }

    function passArrayJsValueToWasm0(array, malloc) {
        const ptr = malloc(array.length * 4, 4) >>> 0;
        for (let i = 0; i < array.length; i++) {
            const add = addToExternrefTable0(array[i]);
            getDataViewMemory0().setUint32(ptr + 4 * i, add, true);
        }
        WASM_VECTOR_LEN = array.length;
        return ptr;
    }

    function passStringToWasm0(arg, malloc, realloc) {
        if (realloc === undefined) {
            const buf = cachedTextEncoder.encode(arg);
            const ptr = malloc(buf.length, 1) >>> 0;
            getUint8ArrayMemory0().subarray(ptr, ptr + buf.length).set(buf);
            WASM_VECTOR_LEN = buf.length;
            return ptr;
        }

        let len = arg.length;
        let ptr = malloc(len, 1) >>> 0;

        const mem = getUint8ArrayMemory0();

        let offset = 0;

        for (; offset < len; offset++) {
            const code = arg.charCodeAt(offset);
            if (code > 0x7F) break;
            mem[ptr + offset] = code;
        }
        if (offset !== len) {
            if (offset !== 0) {
                arg = arg.slice(offset);
            }
            ptr = realloc(ptr, len, len = offset + arg.length * 3, 1) >>> 0;
            const view = getUint8ArrayMemory0().subarray(ptr + offset, ptr + len);
            const ret = cachedTextEncoder.encodeInto(arg, view);

            offset += ret.written;
            ptr = realloc(ptr, len, offset, 1) >>> 0;
        }

        WASM_VECTOR_LEN = offset;
        return ptr;
    }

    function takeFromExternrefTable0(idx) {
        const value = wasm.__wbindgen_externrefs.get(idx);
        wasm.__externref_table_dealloc(idx);
        return value;
    }

    let cachedTextDecoder = new TextDecoder('utf-8', { ignoreBOM: true, fatal: true });
    cachedTextDecoder.decode();
    function decodeText(ptr, len) {
        return cachedTextDecoder.decode(getUint8ArrayMemory0().subarray(ptr, ptr + len));
    }

    const cachedTextEncoder = new TextEncoder();

    if (!('encodeInto' in cachedTextEncoder)) {
        cachedTextEncoder.encodeInto = function (arg, view) {
            const buf = cachedTextEncoder.encode(arg);
            view.set(buf);
            return {
                read: arg.length,
                written: buf.length
            };
        };
    }

    let WASM_VECTOR_LEN = 0;

    let wasmModule, wasmInstance, wasm;
    function __wbg_finalize_init(instance, module) {
        wasmInstance = instance;
        wasm = instance.exports;
        wasmModule = module;
        cachedDataViewMemory0 = null;
        cachedUint8ArrayMemory0 = null;
        wasm.__wbindgen_start();
        return wasm;
    }

    async function __wbg_load(module, imports) {
        if (typeof Response === 'function' && module instanceof Response) {
            if (typeof WebAssembly.instantiateStreaming === 'function') {
                try {
                    return await WebAssembly.instantiateStreaming(module, imports);
                } catch (e) {
                    const validResponse = module.ok && expectedResponseType(module.type);

                    if (validResponse && module.headers.get('Content-Type') !== 'application/wasm') {
                        console.warn("`WebAssembly.instantiateStreaming` failed because your server does not serve Wasm with `application/wasm` MIME type. Falling back to `WebAssembly.instantiate` which is slower. Original error:\n", e);

                    } else { throw e; }
                }
            }

            const bytes = await module.arrayBuffer();
            return await WebAssembly.instantiate(bytes, imports);
        } else {
            const instance = await WebAssembly.instantiate(module, imports);

            if (instance instanceof WebAssembly.Instance) {
                return { instance, module };
            } else {
                return instance;
            }
        }

        function expectedResponseType(type) {
            switch (type) {
                case 'basic': case 'cors': case 'default': return true;
            }
            return false;
        }
    }

    function initSync(module) {
        if (wasm !== undefined) return wasm;


        if (module !== undefined) {
            if (Object.getPrototypeOf(module) === Object.prototype) {
                ({module} = module)
            } else {
                console.warn('using deprecated parameters for `initSync()`; pass a single object instead')
            }
        }

        const imports = __wbg_get_imports();
        if (!(module instanceof WebAssembly.Module)) {
            module = new WebAssembly.Module(module);
        }
        const instance = new WebAssembly.Instance(module, imports);
        return __wbg_finalize_init(instance, module);
    }

    async function __wbg_init(module_or_path) {
        if (wasm !== undefined) return wasm;


        if (module_or_path !== undefined) {
            if (Object.getPrototypeOf(module_or_path) === Object.prototype) {
                ({module_or_path} = module_or_path)
            } else {
                console.warn('using deprecated parameters for the initialization function; pass a single object instead')
            }
        }

        if (module_or_path === undefined && script_src !== undefined) {
            module_or_path = script_src.replace(/\.js$/, "_bg.wasm");
        }
        const imports = __wbg_get_imports();

        if (typeof module_or_path === 'string' || (typeof Request === 'function' && module_or_path instanceof Request) || (typeof URL === 'function' && module_or_path instanceof URL)) {
            module_or_path = fetch(module_or_path);
        }

        const { instance, module } = await __wbg_load(await module_or_path, imports);

        return __wbg_finalize_init(instance, module);
    }

    return Object.assign(__wbg_init, { initSync }, exports);
})({ __proto__: null });
