// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ELibrary {

    address public admin;
    uint public rewardAmount;

    enum Role { None, Author, Student }

    struct Resource {
        uint id;
        string title;
        string contentHash;
        address payable author;
        uint price;
        bool exists;
    }

    uint public resourceCount;
    mapping(uint => Resource) public resources;
    mapping(address => Role) public roles;
    mapping(address => mapping(uint => bool)) public purchasedResources;
    mapping(address => uint) public purchaseCount; // Track the number of resources a student has purchased


    event ResourceAdded(uint resourceId, string title, address author);
    event ResourcePurchased(uint resourceId, address student);
    event RewardPaid(address author, uint amount);
    event RoleAssigned(address indexed user, Role role);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyAuthor() {
        require(roles[msg.sender] == Role.Author, "Only authors can perform this action");
        _;
    }

    modifier onlyStudent() {
        require(roles[msg.sender] == Role.Student, "Only students can perform this action");
        _;
    }

    modifier resourceExists(uint resourceId) {
        require(resources[resourceId].exists, "Resource does not exist");
        _;
    }

    constructor(uint _rewardAmount) {
        admin = msg.sender;
        rewardAmount = _rewardAmount;
    }

    // Admin functions
    function registerAuthor(address author) external onlyAdmin {
        roles[author] = Role.Author;
    }

    function registerStudent(address student) external onlyAdmin {
        roles[student] = Role.Student;
    }

    function setRewardAmount(uint _rewardAmount) external onlyAdmin {
        rewardAmount = _rewardAmount;
    }

    // Author functions
    function addResource(string calldata title, string calldata contentHash, uint price) external onlyAuthor {
        resourceCount++;
        resources[resourceCount] = Resource(resourceCount, title, contentHash, payable(msg.sender), price, true);
        emit ResourceAdded(resourceCount, title, msg.sender);

        // Pay reward to author
        require(address(this).balance >= rewardAmount, "Insufficient funds for reward");
        payable(msg.sender).transfer(rewardAmount);
    }

    // Student functions
    function purchaseResource(uint resourceId) external payable onlyStudent resourceExists(resourceId) {
        Resource memory resource = resources[resourceId];
         uint discount = 0;

        // Check if the student has purchased more than one resource
        if (purchaseCount[msg.sender] > 0) {
            if (purchaseCount[msg.sender] == 1) {
                discount = 20; // 20% discount for the second purchase
            } else {
                discount = 30; // 30% discount for the third and subsequent purchases
            }
        }

        uint priceAfterDiscount = resource.price * (100 - discount) / 100;
        require(msg.value >= priceAfterDiscount, "Insufficient payment");
         // Transfer payment to the author
        resource.author.transfer(priceAfterDiscount);
    }
        function viewResource (uint resourceId) external view onlyStudent resourceExists(resourceId) returns (string memory)
         {
        require(purchasedResources[msg.sender][resourceId], "Resource not purchased");
        return resources[resourceId].contentHash;
        
    }
    // Admin functions to manage funds
    function depositFunds() external payable onlyAdmin {}

    function withdrawFunds(uint amount) external onlyAdmin {
        require(amount <= address(this).balance - rewardAmount, "Insufficient balance for withdrawal");
        payable(admin).transfer(amount);
    }

    // Fallback to receive Ether
    receive() external payable {}
}

