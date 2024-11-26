// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// This contract implements a conditional payment system for a wine shipping agreement between a merchant (buyer) and a shipping company (seller).
// The seller holds responsibility for timely delivery, and the buyer deposits payment in escrow. 
// The contract is self-executing, with an oracle (activator) triggering payment release based on delivery conditions.

contract ConditionalTokenSwap {
    // Mapping to track token balances for each address (representing performance-based obligations)
    mapping(address => uint256) public tokenBalances;
    uint256 public totalSupply = 1000; // Total supply of tokens representing the wine shipment

    // Roles:
    address public issuer;    // Address representing the shipping company (seller)
    address public buyer;     // Address representing the merchant (buyer) depositing payment
    address public activator; // Oracle address authorized to trigger payment based on delivery status

    // Payment deposited by the buyer into escrow for the shipment
    uint256 public ethDeposited;
    uint256 public constant tokenPrice = 0.2 ether; // Fixed payment amount for the wine shipment

    // Events for contract transparency
    event TokensIssued(address indexed to, uint256 amount);  // Emitted when shipment responsibility is assigned to the seller
    event ETHDeposited(address indexed from, uint256 amount); // Emitted when payment is deposited by the buyer
    event SwapExecuted(address indexed buyer, address indexed issuer, uint256 tokensSwapped, uint256 ethSwapped); // Emitted when payment is released upon successful delivery

    // Constructor to initialize contract roles and assign responsibility for the shipment to the seller
    constructor(address _issuer, address _buyer, address _activator) {
        issuer = _issuer;     // The address representing the seller responsible for shipment
        buyer = _buyer;       // The address representing the buyer depositing payment
        activator = _activator; // The oracle verifying delivery and triggering payment release

        // Assign full shipment responsibility (tokens) to the seller at deployment
        tokenBalances[issuer] = totalSupply;

        // Emit an event to confirm assignment of shipment responsibility
        emit TokensIssued(issuer, totalSupply);
    }

    // Modifier to restrict certain actions to the activator (oracle)
    modifier onlyActivator() {
        require(msg.sender == activator, "Only the activator can perform this action."); // Ensures only the oracle can trigger payment release
        _;
    }

    // Function for the buyer to deposit payment into escrow
    function depositETH() public payable {
        require(msg.sender == buyer, "Only the buyer can deposit ETH."); // Restrict to buyer's address
        require(ethDeposited == 0, "ETH already deposited."); // Prevent multiple deposits
        require(msg.value == tokenPrice, "Incorrect ETH amount. Must be 0.2 ETH."); // Ensure exact payment amount

        // Record the deposited payment
        ethDeposited = msg.value;

        // Emit an event to track payment deposit
        emit ETHDeposited(msg.sender, msg.value);
    }

    // Function to trigger payment release (activator-controlled action)
    function triggerSwap() public onlyActivator {
        // Ensure conditions for payment release are met
        require(ethDeposited > 0, "No ETH deposited."); // Buyer must have deposited payment
        require(ethDeposited == tokenPrice, "ETH amount does not match the token price."); // Confirm exact deposit amount
        require(tokenBalances[issuer] == totalSupply, "Issuer does not own all tokens."); // Validate seller's shipment responsibility

        // Swap shipment obligation and payment between buyer and seller
        uint256 tokensToSwap = totalSupply; // Full shipment responsibility being transferred
        uint256 ethToSwap = ethDeposited;   // Payment being released to the seller

        // Transfer tokens (shipment completion) from seller to buyer
        tokenBalances[issuer] -= tokensToSwap; 
        tokenBalances[buyer] += tokensToSwap;

        // Transfer payment from escrow to seller
        payable(issuer).transfer(ethToSwap);

        // Reset the payment deposit after release
        ethDeposited = 0;

        // Emit an event to confirm payment release and shipment completion
        emit SwapExecuted(buyer, issuer, tokensToSwap, ethToSwap);
    }

    // Function to check the ETH balance held by the contract (useful for debugging or auditing)
    function getContractETHBalance() public view returns (uint256) {
        return address(this).balance; // Returns the balance of ETH in the contract
    }
}
