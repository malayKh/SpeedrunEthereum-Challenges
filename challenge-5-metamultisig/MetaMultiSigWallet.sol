// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
// Not needed to be explicitly imported in Solidity 0.8.x
// pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MetaMultiSigWallet {
    using ECDSA for bytes32;

    event Deposit(address indexed sender, uint amount, uint balance);
    event ExecuteTransaction(address indexed owner, address payable to, uint256 value, bytes data, uint256 nonce, bytes32 _hash, bytes result);
    event Owner(address indexed owner, bool added);

    mapping (address => bool) public isOwner;
    uint public minimumSignatures;
    uint public nonce;
    uint public chainId;

    constructor (uint _chainId, address[] memory owners, uint _minimumSignatures){
        require(minimumSignatures > 0, "Cant have 0 signatures");
        chainId = _chainId;
        minimumSignatures = _minimumSignatures;
        for (uint i = 0; i < owners.length; i++){
            address owner = owners[i];
            require(owner != address(0),  "constructor: zero address");
            require(!isOwner[owner], "Address is already an owner");
            isOwner[owner] = true;
            emit Owner(owner, isOwner[owner]);
        }
    }

    
    modifier onlySelf() {
        require(msg.sender == address(this), "Not Self");
        _;
    }

    function addSigner (address newSigner, uint newValidSigs) public onlySelf{
        require(newSigner != address(0), "Zero address cant be added");
        require(!isOwner[newSigner], "Address already exists!");
        require(newValidSigs > 0, "There needs to be a minimum amount of sigs greater than zero");

        isOwner[newSigner] = true;
        minimumSignatures = newValidSigs;
        emit Owner(newSigner, isOwner[newSigner]);
    } 

    function removeSigner (address oldSigner, uint newValidSigs) public onlySelf{
        require(isOwner[oldSigner], "Signer does not exist!");
        require(newValidSigs > 0, "There needs to be a minimum amount of sigs greater than zero");
        isOwner[oldSigner] = false;
        minimumSignatures = newValidSigs;
        emit Owner(oldSigner, isOwner[oldSigner]);
    }

    function updateSignaturesRequired (uint newValidSigs) public onlySelf{
        require(newValidSigs > 0, "There needs to be a minimum amount of sigs greater than zero");
        minimumSignatures = newValidSigs;
    }
    function getTransactionHash(uint _nonce , address to, uint value, bytes memory data) public view returns (bytes32){
        return keccak256(abi.encodePacked(address(this),chainId,nonce,to,value,data));
    }

    function sendTransaction(address payable to, uint value, uint amount, bytes memory data, bytes[] memory signatures) public returns (bytes memory){
        require(isOwner[msg.sender], "Only owners can execute transactions"); 
        bytes32 _hash = getTransactionHash(nonce, to, value, data);
        nonce ++;
        uint validSigs;
        address duplicateGuard;
        for (uint i = 0; i < signatures.length; i++) {
            address recovered = recover(_hash, signatures[i]);
            require(recovered > duplicateGuard, "executeTransaction: duplicate or unordered signatures");
            duplicateGuard = recovered;
            if(isOwner[recovered]){
              validSigs++;
            }
        }
        require(validSigs >= minimumSignatures, "Not enough signatures");
        (bool success, bytes memory result) = to.call{value: value}(data);
        require(success == true, "Transaction failed!" );

        emit ExecuteTransaction(msg.sender, to, value, data, nonce-1, _hash, result);
        return result;
    }

    
    function recover(bytes32 _hash, bytes memory _signature) public pure returns (address) {
        return _hash.toEthSignedMessageHash().recover(_signature);
    }

    receive() payable external {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

}
