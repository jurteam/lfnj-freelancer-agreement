![Jur](/logo.png)
# Freelancer's Agreement - Lab for New Justice
This repository contains the template for the smart legal contracts designed to replicate the basic behaviour of a legal contract between a freelancer and a customer.

## Deployment
```
constructor(
        address _jurToken,
        bytes32 _agreementHash,
        uint _submittionDeadline,
        uint _contractValidity,
        uint _contractWarranty,
        uint _lateDeliveryPenalty,
        uint _totalPayout
)
```
1. **_jurToken** is the address of the JUR Token contract on the network.
2. **_agreementHash** is the hash of the agreement document between parties.
3. **_submittionDeadline** is the number of days given to the freelancer to perform the service.
4. **_contractValidity** is the number of days the contract will be valid for.
5. **_contractWarranty** is the number of days the performance will be under warranty for.
6  **_lateDeliveryPenalty** is the percentage of payout which will deducted each day as penalty for late submission.
7. **_totalPayout** is the payment in JUR Tokens which will be given to the freelancer at the acceptance of delivery.
## Functions
### 1. Add customer's details
```
addCustomerDetails(
        address _partyAddress,
        string memory _name,
        string memory _countryOfOperation,
        string memory _postalAddress,
        uint _fiscalIdentificationNumber
)
```
Function for adding the Customer's details.
1. **_partyAddress** is the VeChain network address of the customer which will be used for executing transactions.
2. **_name** represents the customer's name. (String)
3. **_countryOfOperation** represents the customer's country. (String)
4. **_postalAddress** represents the customer's address. (String)
5. **_fiscalIdentificationNumber** represents the customer's fiscal code. (String)

### 2. Add freelancer's details
```
addFreelancerDetails(
        address _partyAddress,
        string memory _name,
        string memory _countryOfOperation,
        string memory _postalAddress,
        uint _fiscalIdentificationNumber
)
```
Function for adding Freelancer's details.
1. **_partyAddress** is the VeChain network address of the freelancer which will be used for executing transactions.
2. **_name** represents the freelancer's name. (String)
3. **_countryOfOperation** represents the freelancer's country. (String)
4. **_postalAddress** represents the freelancer's address. (String)
5. **_fiscalIdentificationNumber** represents the freelancer's fiscal code. (String)

### 3. Sign Agreement
```
signAgreement()
```
Function used by both parties to sign the agreement. This function should only be called respectively by the addresses mentioned above.
In case of the customer, it is required that the customer should first approve the agreement contract to transfer tokens on her behalf.
Please refer to the preparatory material to understand how.

### 4. Deliver the project
```
markProjectComplete()
```
This function is called by the freelancer to update the customer on the delivery of the project. It automatically calculates the late delivery penalty if any, and updates the payout.

### 5. Release the payout
```
releasePayout()
```
This function can only be called by the customer to release the payment for the freelancer.

### 6. Grant a license
```
uploadLicence(bytes32 _licenseHash, string _name)
```
Either party can use this function to upload a license they wish to grant the other party.
1. **_licenseHash** is the hash of the document containing the license.
2. **_name** is the name of the license.
