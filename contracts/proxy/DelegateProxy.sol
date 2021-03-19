pragma solidity >=0.6.0;


// Inheritance
import "../vendor/Owned.sol";

// Internal references
import "@openzeppelin/contracts/proxy/Proxy.sol";

import "hardhat/console.sol";


contract DelegateProxy is Proxy {
    bytes32 internal constant OWNER_KEY = keccak256("proxy.owner");
    bytes32 internal constant PROXY_KEY = keccak256("proxy.impl");

    event ProxyTargetUpdated(address newTarget);

    constructor(address _owner) 
        public 
    {
        _setOwner(_owner);
    }
    
    function proxy_setOwner(address _owner) 
        public 
        onlyOwner 
    {
        _setOwner(_owner);
    }

    function proxy_setTarget(address _target) 
        public 
        onlyOwner 
    {
        bytes32 slot = PROXY_KEY;
        assembly {
            sstore(slot, _target)
        }
        emit ProxyTargetUpdated(_target);
    }

    function proxy_owner() 
        public 
        view 
        returns (address _owner) 
    {
        bytes32 slot = OWNER_KEY;
        assembly {
            _owner := sload(slot)
        }
    }

    function proxy_target() 
        public 
        view 
        returns (address) 
    {
        return _implementation();
    }

    function _setOwner(address _owner) 
        internal 
    {
        bytes32 slot = OWNER_KEY;
        assembly {
            sstore(slot, _owner)
        }
    }

    function _implementation() 
        internal 
        view 
        override 
        returns (address _target) 
    {
        bytes32 slot = PROXY_KEY;
        assembly {
            _target := sload(slot)
        }
    }

    modifier onlyOwner() {
        require(msg.sender == proxy_owner(), "ERR_ONLY_OWNER");
        _;
    }
}