pragma solidity 0.4.24;

/**
 * @title GOLD-C
 * @dev ERC20-style token representing claims against allocated gold held off-chain.
 *
 * Each token unit uses 18 decimals. The issuer must define the real-world
 * redemption ratio, custody terms, audits, and compliance process off-chain.
 */
contract GoldCToken {
    string public constant name = "Gold-C";
    string public constant symbol = "GOLD-C";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;

    address public owner;
    bool public paused;

    mapping(address => bool) public custodians;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event CustodianUpdated(address indexed custodian, bool enabled);
    event Paused();
    event Unpaused();
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

    constructor() public {
        owner = msg.sender;
        custodians[msg.sender] = true;

        emit OwnershipTransferred(address(0), msg.sender);
        emit CustodianUpdated(msg.sender, true);
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function allowance(address tokenOwner, address spender) external view returns (uint256) {
        return allowed[tokenOwner][spender];
    }

    function transfer(address to, uint256 value) external whenNotPaused returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external whenNotPaused returns (bool) {
        require(spender != address(0), "Cannot approve zero address");

        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external whenNotPaused returns (bool) {
        require(value <= allowed[from][msg.sender], "Transfer exceeds allowance");

        allowed[from][msg.sender] = allowed[from][msg.sender] - value;
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Mints GOLD-C after verified gold has been deposited with the issuer/custodian.
     * @param to Receiver of the newly issued tokens.
     * @param value Token amount, using 18 decimals.
     * @param reference Off-chain custody/deposit reference.
     */
    function mint(address to, uint256 value, string reference) external onlyCustodian whenNotPaused returns (bool) {
        require(to != address(0), "Cannot mint to zero address");

        totalSupply = _add(totalSupply, value);
        balances[to] = _add(balances[to], value);

        emit Minted(msg.sender, to, value, reference);
        emit Transfer(address(0), to, value);
        return true;
    }

    /**
     * @dev Burns caller tokens during redemption or cancellation.
     * @param value Token amount, using 18 decimals.
     * @param reference Off-chain redemption reference.
     */
    function burn(uint256 value, string reference) external whenNotPaused returns (bool) {
        _burn(msg.sender, value, reference);
        return true;
    }

    /**
     * @dev Custodian burn for completed redemptions handled on behalf of a holder.
     */
    function custodianBurn(address from, uint256 value, string reference) external onlyCustodian returns (bool) {
        _burn(from, value, reference);
        return true;
    }

    function setCustodian(address custodian, bool enabled) external onlyOwner {
        require(custodian != address(0), "Invalid custodian");

        custodians[custodian] = enabled;
        emit CustodianUpdated(custodian, enabled);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");

        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    /**
     * @dev Publishes an immutable pointer to an off-chain reserve report.
     * `reportHash` can be keccak256 of the report contents, and `uri` can point
     * to an IPFS CID, HTTPS URL, or internal audit reference.
     */
    function publishReserveReport(bytes32 reportHash, string uri) external onlyOwner {
        emit ReserveReportPublished(reportHash, uri);
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "Cannot transfer to zero address");
        require(value <= balances[from], "Transfer exceeds balance");

        balances[from] = balances[from] - value;
        balances[to] = _add(balances[to], value);

        emit Transfer(from, to, value);
    }

    function _burn(address from, uint256 value, string reference) internal {
        require(from != address(0), "Cannot burn from zero address");
        require(value <= balances[from], "Burn exceeds balance");

        balances[from] = balances[from] - value;
        totalSupply = totalSupply - value;

        emit Burned(from, value, reference);
        emit Transfer(from, address(0), value);
    }

    function _add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Addition overflow");
        return c;
    }
}
