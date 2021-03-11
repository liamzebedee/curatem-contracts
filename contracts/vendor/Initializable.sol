contract Initializable {
    bool _initialized = false;

    modifier uninitialized() {
        require(_initialized == false, "ERR_ALREADY_INITIALIZED");
        _;
        _initialized = true;
    }

    modifier isInitialized() {
        require(_initialized, "ERR_UNINITIALIZED");
        _;
    }
}