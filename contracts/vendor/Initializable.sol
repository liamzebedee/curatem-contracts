contract Initializable {
    bool _initialized = false;
    modifier uninitialized() {
        require(_initialized == false, "already initialized");
        _;
        _initialized = true;
    }
}