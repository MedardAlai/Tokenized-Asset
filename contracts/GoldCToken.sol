// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title GOLD-C
 * @dev ERC20 token representing claims against allocated gold held off-chain.
 *
 * This contract only covers the on-chain token mechanics. The redemption ratio,
 * custody terms, audits, transfer restrictions, sanctions screening, and other
 * compliance requirements must be defined and enforced through the issuer's
 * legal and operational framework.
 */
contract GoldCToken {
    string public constant name = "Gold-C";
    string public constant symbol = "GOLD-C";
    uint8 public constant decimals = 18;

    uint256 public constant CUSTODIAN_CHANGE_DELAY = 2 days;

    uint256 public totalSupply;
    address public owner;
    address public pendingOwner;
    bool public paused;

    struct PendingCustodianChange {
        bool enabled;
        uint64 executeAfter;
        bool exists;
    }

    mapping(address => bool) public custodians;
    mapping(address => PendingCustodianChange) public pendingCustodianChanges;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 value);
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event CustodianChangeScheduled(address indexed custodian, bool enabled, uint64 executeAfter);
    event CustodianChangeCancelled(address indexed custodian);
    event CustodianUpdated(address indexed custodian, bool enabled);
    event Paused(address indexed account);
    event Unpaused(address indexed account);
    event Minted(address indexed custodian, address indexed to, uint256 value, string reference);
    event Burned(address indexed from, uint256 value, string reference);
    event ReserveReportPublished(bytes32 indexed reportHash, string uri);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyCustodian() {
        require(custodians[msg.sender], "Only custodian");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Token is paused");
        _;
    }

    constructor() {
        owner = msg.sender;
        custodians[msg.sender] = true;

        emit OwnershipTransferred(address(0), msg.sender);
        emit CustodianUpdated(msg.sender, true);
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function allowance(address tokenOwner, address spender) external view returns (uint256) {
        return _allowances[tokenOwner][spender];
    }

    function transfer(address to, uint256 value) external whenNotPaused returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Sets allowance. To reduce the classic ERC20 allowance race condition,
     * changing a non-zero allowance to another non-zero value must use
     * increaseAllowance/decreaseAllowance or first set the allowance to zero.
     */
    function approve(address spender, uint256 value) external whenNotPaused returns (bool) {
        require(value == 0 || _allowances[msg.sender][spender] == 0, "Reset allowance to zero first");
        _approve(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external whenNotPaused returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Decreased allowance below zero");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external whenNotPaused returns (bool) {
        _spendAllowance(from, msg.sender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Mints GOLD-C after verified gold has been deposited with the issuer/custodian.
     * @param to Receiver of the newly issued tokens.
     * @param value Token amount, using 18 decimals.
     * @param reference Off-chain custody/deposit reference.
     */
    function mint(address to, uint256 value, string calldata reference) external onlyCustodian whenNotPaused returns (bool) {
        require(to != address(0), "Cannot mint to zero address");

        totalSupply += value;
        _balances[to] += value;

        emit Minted(msg.sender, to, value, reference);
        emit Transfer(address(0), to, value);
        return true;
    }

    /**
     * @dev Burns caller tokens during redemption or cancellation.
     * @param value Token amount, using 18 decimals.
     * @param reference Off-chain redemption reference.
     */
    function burn(uint256 value, string calldata reference) external whenNotPaused returns (bool) {
        _burn(msg.sender, value, reference);
        return true;
    }

    /**
     * @dev Burns holder tokens for a completed redemption. The holder must approve
     * the custodian first, preventing custodians from burning arbitrary balances.
     */
    function custodianBurn(address from, uint256 value, string calldata reference)
        external
        onlyCustodian
        whenNotPaused
        returns (bool)
    {
        _spendAllowance(from, msg.sender, value);
        _burn(from, value, reference);
        return true;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");

        pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner, newOwner);
    }

    function acceptOwnership() external {
        require(msg.sender == pendingOwner, "Only pending owner");

        address previousOwner = owner;
        owner = pendingOwner;
        pendingOwner = address(0);

        emit OwnershipTransferred(previousOwner, owner);
    }

    /**
     * @dev Schedules custodian changes with a delay, giving holders time to react
     * before a new custodian can mint or burn approved redemptions.
     */
    function scheduleCustodianChange(address custodian, bool enabled) external onlyOwner {
        require(custodian != address(0), "Invalid custodian");

        uint64 executeAfter = uint64(block.timestamp + CUSTODIAN_CHANGE_DELAY);
        pendingCustodianChanges[custodian] = PendingCustodianChange({
            enabled: enabled,
            executeAfter: executeAfter,
            exists: true
        });

        emit CustodianChangeScheduled(custodian, enabled, executeAfter);
    }

    function cancelCustodianChange(address custodian) external onlyOwner {
        require(pendingCustodianChanges[custodian].exists, "No pending change");

        delete pendingCustodianChanges[custodian];
        emit CustodianChangeCancelled(custodian);
    }

    function executeCustodianChange(address custodian) external {
        PendingCustodianChange memory pendingChange = pendingCustodianChanges[custodian];
        require(pendingChange.exists, "No pending change");
        require(block.timestamp >= pendingChange.executeAfter, "Change delay active");

        custodians[custodian] = pendingChange.enabled;
        delete pendingCustodianChanges[custodian];

        emit CustodianUpdated(custodian, pendingChange.enabled);
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Publishes an immutable pointer to an off-chain reserve report.
     * `reportHash` can be keccak256 of the report contents, and `uri` can point
     * to an IPFS CID, HTTPS URL, or internal audit reference.
     */
    function publishReserveReport(bytes32 reportHash, string calldata uri) external onlyOwner {
        require(reportHash != bytes32(0), "Invalid report hash");
        emit ReserveReportPublished(reportHash, uri);
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "Cannot transfer from zero address");
        require(to != address(0), "Cannot transfer to zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= value, "Transfer exceeds balance");

        unchecked {
            _balances[from] = fromBalance - value;
        }
        _balances[to] += value;

        emit Transfer(from, to, value);
    }

    function _burn(address from, uint256 value, string calldata reference) internal {
        require(from != address(0), "Cannot burn from zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= value, "Burn exceeds balance");

        unchecked {
            _balances[from] = fromBalance - value;
            totalSupply -= value;
        }

        emit Burned(from, value, reference);
        emit Transfer(from, address(0), value);
    }

    function _approve(address tokenOwner, address spender, uint256 value) internal {
        require(tokenOwner != address(0), "Cannot approve from zero address");
        require(spender != address(0), "Cannot approve zero address");

        _allowances[tokenOwner][spender] = value;
        emit Approval(tokenOwner, spender, value);
    }

    function _spendAllowance(address tokenOwner, address spender, uint256 value) internal {
        uint256 currentAllowance = _allowances[tokenOwner][spender];

        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= value, "Transfer exceeds allowance");
            unchecked {
                _approve(tokenOwner, spender, currentAllowance - value);
            }
        }
    }
}
