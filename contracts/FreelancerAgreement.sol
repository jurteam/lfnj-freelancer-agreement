pragma solidity >=0.4.21 <0.7.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract FreelancerAgreement {
    using SafeMath for uint;
    //Initialise state
    enum State {Unsigned, Signed, Delivered, Completed, Dispute, Closed}
    State public state = State.Unsigned;

    enum Roles {Customer, Freelancer}

    uint private MAX_DELIVERY_DEADLINE; //3 months
    uint private CONTRACT_WARRANTY; //2 years
    uint private CONTRACT_VALIDITY; //5 years
    uint public CONTRACT_WARRANTY_EXPIRATION;
    uint public CONTRACT_VALIDITY_EXPIRATION;
    uint public DELIVERY_DEADLINE;
    uint public LATE_DELIVERY_PENALTY;
    uint public PAYOUT;

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


    modifier hasState(State _state) {
        require(state == _state, "Invalid state");
        _;
    }

    modifier isParty(address _sender) {
        require(_sender != address(0), "Address is not a party.");
        require(_sender == customer.partyAddress || _sender == freelancer.partyAddress, "Address is not a party.");
    }

    modifier isCustomer(address _sender) {
        require(_sender != address(0), "Address is not a party.");
        require(_sender == customer.partyAddress, "Address is not a party.");
    }

    constructor(
        address _jurToken,
        bytes32 _agreementHash,
        uint _submittionDeadline,
        uint _contractValidity,
        uint _contractWarranty,
        uint _totalPayout
    )
        public
    {
        //Initialise JUR token
        jurToken = ERC20(_jurToken);
        agreementHash = _agreementHash;

        MAX_WORK_SUBMIT_DEADLINE = _submittionDeadline;
        CONTRACT_WARRANTY = _contractWarranty;
        CONTRACT_VALIDITY = _contractValidity;
        LATE_DELIVERY_PENALTY = _lateDeliveryPenalty;
        PAYOUT = _totalPayout;

        emit ContractCreated(_agreementHash);
    }

    function addPartyDetails(
        Role _role,
        address _partyAddress,
        string _name,
        string _countryOfOperation,
        string _postalAddress,
        uint _fiscalIdentificationNumber
    )
        public
        onlyOwner
        hasState(State.Unsigned)
    {
        require(_partyAddress != address(0), "Address cannot be empty");
        Party storage _party = Party(_partyAddress, Roles.Customer, _name, _countryOfOperation, _postalAddress, _fiscalIdentificationNumber);
        if(_role == Roles.Customer) {
            customer = _party;
        } else if(_role == Roles.Freelancer) {
            freelancer = _party;
        }
    }

    function signAgreement() public hasState(State.Unsigned) isParty(msg.sender) {
        require(!hasSigned[msg.sender], "This address has already signed.");
        hasSigned[msg.sender] = true;
        if(msg.sender == customer.partyAddress){
            require(jurToken.transferFrom(msg.sender, address(this), PAYOUT), "Could not transfer the tokens.");
        }
        bool allSigned = false;

        if(hasSigned[customer.partyAddress] && hasSigned[freelancer.partyAddress]) {allSigned = true;}

        if (allSigned) {
            setState(State.Signed);
            CONTRACT_VALIDITY_EXPIRATION = SafeMath.add(getNow, CONTRACT_VALIDITY);
            CONTRACT_WARRANTY_EXPIRATION = SafeMath.add(getNow, CONTRACT_WARRANTY);
            DELIVERY_DEADLINE = SafeMath.add(getNow, MAX_DELIVERY_DEADLINE);
        }
        emit ContractSigned(msg.sender);
    }

    function markProjectComplete() public isParty(msg.sender) {
        setState(State.Delivered);
        if(getNow() > DELIVERY_DEADLINE) {
            //TODO divide this by number of miliseconds in a day.
            uint daysExtended = SafeMath.sub(getNow(), DELIVERY_DEADLINE);
            uint dailyPenalty = SafeMath.div(SafeMath.mul(LATE_DELIVERY_PENALTY, PAYOUT), 100);
            PAYOUT = SafeMath.sub(PAYOUT, SafeMath.mul(dailyPenalty, daysExtended));
        }
        emit ProjectDelievered();
    }

    function releasePayout() public isCustomer(msg.sender) hasState(State.Delivered) {
        setState(State.Completed);
        require(jurToken.transfer(freelancer.partyAddress, PAYOUT), "Could not transfer funds.");
        emit PaymentReleased(PAYOUT, getNow());
    }

    function setState(State _state) internal {
        emit StateChange(state, _state, getNow());
        state = _state;
    }

    function uploadLicence(bytes32 _licenseHash, string _name) public isParty(msg.sender) {
        licenses[licenseCount++] = License(_licenseHash, _name, msg.sender);
        emit LicenseAdded(_name, msg.sender);
    }

    /**
    * @notice Returns current timestamp
    */
    function getNow() internal view returns (uint256) {
        return now;
    }
}