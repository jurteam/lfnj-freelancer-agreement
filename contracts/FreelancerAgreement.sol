pragma solidity >=0.4.21 <0.7.0;
import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FreelancerAgreement {
    using SafeMath for uint;
    //Initialise state
    enum State {Unsigned, Signed, Delivered, Completed, Dispute, Closed}
    State public state = State.Unsigned;

    enum Roles {Customer, Freelancer}

    uint private maxDeliveryDeadline; //3 months
    uint private contractWarranty; //2 years
    uint private contractValidity; //5 years
    uint public contractWarrantyExpiration;
    uint public contractValidityExpiration;
    uint public deliveryDeadline;
    uint public lateDeliveryPenalty;
    uint public payout;
    uint private secondsInADay = 86400;

    //Token for escrow & voting
    ERC20 public jurToken;
    bytes32 agreementHash;

    struct Party {
        address partyAddress;
        Roles role;
        string name;
        string countryOfOperation;
        string postalAddress;
        uint fiscalIdentificationNumber;
    }

    struct License {
        bytes32 licenseHash;
        string name;
        address owner;
    }

    Party public customer;
    Party public freelancer;
    mapping (address => bool) public hasSigned;
    mapping(uint => License) public licences;

    uint private licenseCount = 0;

    event LicenseAdded(string _name, address _owner);
    event PaymentReleased(uint _payout, uint _timestamp);
    event ContractCreated(bytes32 _agreementHash);
    event ContractSigned(address _signer);
    event ProjectDelievered();
    event StateChange(State state, State _state, uint _timestamp);


    modifier hasState(State _state) {
        require(state == _state, "Invalid state");
        _;
    }

    modifier isParty(address _sender) {
        require(_sender != address(0), "Address is not a party.");
        require(_sender == customer.partyAddress || _sender == freelancer.partyAddress, "Address is not a party.");
        _;
    }

    modifier isCustomer(address _sender) {
        require(_sender != address(0), "Address is not a party.");
        require(_sender == customer.partyAddress, "Address is not a party.");
        _;
    }
    //All are in days.
    constructor(
        address _jurToken,
        bytes32 _agreementHash,
        uint _submittionDeadline,
        uint _contractValidity,
        uint _contractWarranty,
        uint _lateDeliveryPenalty,
        uint _totalPayout
    )
        public
    {
        //Initialise JUR token
        jurToken = ERC20(_jurToken);
        agreementHash = _agreementHash;

        maxDeliveryDeadline = _submittionDeadline;
        contractWarranty = _contractWarranty;
        contractValidity = _contractValidity;
        lateDeliveryPenalty = _lateDeliveryPenalty;
        payout = _totalPayout;

        emit ContractCreated(_agreementHash);
    }

    function addCustomerDetails(
        address _partyAddress,
        string memory _name,
        string memory _countryOfOperation,
        string memory _postalAddress,
        uint _fiscalIdentificationNumber
    )
        public
        hasState(State.Unsigned)
    {
        require(_partyAddress != address(0), "Address cannot be empty");
        require(customer.partyAddress == address(0), "Details have already been set");
        customer = Party(_partyAddress, Roles.Customer, _name, _countryOfOperation, _postalAddress, _fiscalIdentificationNumber);
    }

    function addFreelancerDetails(
        address _partyAddress,
        string memory _name,
        string memory _countryOfOperation,
        string memory _postalAddress,
        uint _fiscalIdentificationNumber
    )
        public
        hasState(State.Unsigned)
    {
        require(_partyAddress != address(0), "Address cannot be empty");
        require(freelancer.partyAddress == address(0), "Details have already been set");
        customer = Party(_partyAddress, Roles.Freelancer, _name, _countryOfOperation, _postalAddress, _fiscalIdentificationNumber);
    }

    function signAgreement() public hasState(State.Unsigned) isParty(msg.sender) {
        require(!hasSigned[msg.sender], "This address has already signed.");
        hasSigned[msg.sender] = true;
        if(msg.sender == customer.partyAddress){
            require(jurToken.transferFrom(msg.sender, address(this), payout), "Could not transfer the tokens.");
        }
        bool allSigned = false;

        if(hasSigned[customer.partyAddress] && hasSigned[freelancer.partyAddress]) {allSigned = true;}

        if (allSigned) {
            setState(State.Signed);
            contractValidityExpiration = SafeMath.add(getNow(), contractValidity * 1 days);
            contractWarrantyExpiration = SafeMath.add(getNow(), contractWarranty * 1 days);
            deliveryDeadline = SafeMath.add(getNow(), maxDeliveryDeadline * 1 days);
        }
        emit ContractSigned(msg.sender);
    }

    function markProjectComplete() public isParty(msg.sender) {
        setState(State.Delivered);
        if(getNow() > deliveryDeadline) {
            //TODO divide this by number of miliseconds in a day.
            uint daysExtended = SafeMath.sub(getNow(), deliveryDeadline) / secondsInADay;
            uint dailyPenalty = SafeMath.div(SafeMath.mul(lateDeliveryPenalty, payout), 100);
            payout = SafeMath.sub(payout, SafeMath.mul(dailyPenalty, daysExtended));
        }
        emit ProjectDelievered();
    }

    function releasePayout() public isCustomer(msg.sender) hasState(State.Delivered) {
        setState(State.Completed);
        require(jurToken.transfer(freelancer.partyAddress, payout), "Could not transfer funds.");
        emit PaymentReleased(payout, getNow());
    }

    function setState(State _state) internal {
        emit StateChange(state, _state, getNow());
        state = _state;
    }

    function uploadLicence(bytes32 _licenseHash, string memory _name) public isParty(msg.sender) {
        licences[licenseCount++] = License(_licenseHash, _name, msg.sender);
        emit LicenseAdded(_name, msg.sender);
    }

    /**
    * @notice Returns current timestamp
    */
    function getNow() internal view returns (uint256) {
        return now;
    }
}