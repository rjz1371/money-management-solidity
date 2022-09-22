// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

// todo: add "receive" function to get direct money.
// todo: check trader address exists before create request.

/// @author https://www.linkedin.com/in/reza-jabbari-47a10677
/// @notice A simple money management contract based on investors contributing.
contract MoneyManagement {

    // To hold investor's address & invest amounts.
    mapping(address => uint) public investors;

    // To hold total investors count.
    uint public totalInvestors;

    // A trader is actually a money management person.
    struct Trader {
        // Trader name.
        string name;
        // Monthly payback in percent.
        uint monthlyPayback;
        // The total investment that investors assign to the trader.
        uint investorsAssets;
        // Trader address to receive the investor's assets.
        address traderAddress;
    }

    // To hold trader address & Trader structure.
    mapping(address => Trader) public traders;

    // To hold total traders count.
    uint public totalTrders;

    // Minimum invest amount.
    uint minInvestAmount = 500000000000000000; // 0.5 ether

    // A Trader should pay fee to join as a trader.
    uint joiningFeeForTrader = 1000000000000000000; // 1.00 ether

    // Every investor can create a request to transfer a percentage of the money to a trader.
    struct Request {
        uint percentOfAssetsToTransfer;
        address traderAddressToTransfer;
        bool isChosenTotransfer;
        uint votes;
        mapping(address => bool) isInvestorVoted;
    }

    // To hold investor requests.
    Request[] public requests;

    error InsufficientInvestAmount(uint minAmount, uint sendedAmount);
    error InsufficientFeeAmount(uint feeAmount, uint sendedAmount);

    /**
    * @notice This function is used for joining & investing as an investor.
    * Investors can take part in voting to choose a trader person for investing money.
    *
    * @return The total investment amount for the current address.
    */
    function invets() public payable returns(uint) {
        if (msg.value < minInvestAmount) {
            revert InsufficientInvestAmount({minAmount: minInvestAmount, sendedAmount: msg.value});
        }
        if (investors[msg.sender] == 0) {
            totalInvestors += 1;
        }
        investors[msg.sender] = investors[msg.sender] + msg.value;
        
        return investors[msg.sender];
    }

    /**
    * @notice A trader will be added to traders list after pay joining fee.
    *
    * @return Insufficient fee amount error or return true.
    */
    function joiningAsATrader(string memory _name, uint _monthlyPayback) public payable returns(bool) {
        if (msg.value < joiningFeeForTrader) {
            revert InsufficientFeeAmount({feeAmount: joiningFeeForTrader, sendedAmount: msg.value});
        }
        traders[msg.sender] = Trader({
            name: _name,
            monthlyPayback: _monthlyPayback,
            investorsAssets: 0,
            traderAddress: msg.sender
        });
        totalTrders += 1;

        return true;
    }

    /**
    * @notice Investors can create a request to choose to transfer money to a trader.
    *
    * @return Total request count.
    */
    function createRequest(uint _percentOfAssetsToTransfer, address _traderAddressToTransfer) onlyInvestor public returns(uint) {
        Request storage newRequest = requests.push();
        newRequest.percentOfAssetsToTransfer = _percentOfAssetsToTransfer;
        newRequest.traderAddressToTransfer = _traderAddressToTransfer;
        newRequest.isChosenTotransfer = false;
        newRequest.votes = 0;

        return requests.length;
    }

    /**
    * @notice Investors can vote for only one of the request.
    * If there are more than 6 investors & more than 60% of investors vote for this request it will be executed.
    * Executing the request is including transferring money to the trader's address.
    * 
    * @return Total votes count of the request.
    */
    function voteToExecuteRequest(uint _requestIndex) onlyInvestor public returns(uint) {
        require(requests.length > 0 && _requestIndex <= requests.length - 1, "Request does not exist.");
        Request storage request = requests[_requestIndex];
        require(!request.isChosenTotransfer, "This request is already done.");
        require(!request.isInvestorVoted[msg.sender], "You have been already voted.");
        request.isInvestorVoted[msg.sender] = true;
        request.votes += 1;
        
        if (totalInvestors >= 6 && (request.votes * 100) / totalInvestors > 60) {
            traders[request.traderAddressToTransfer].investorsAssets += (address(this).balance * request.percentOfAssetsToTransfer) / 100;
            payable(request.traderAddressToTransfer).transfer((address(this).balance * request.percentOfAssetsToTransfer) / 100);
            request.isChosenTotransfer = true;
        }

        return request.votes;
    }

    /// @return total requests count.
    function totalRequests() public view returns(uint) {
        return requests.length;
    }

    /// Only investors can call this function.
    modifier onlyInvestor() {
        require(investors[msg.sender] >= minInvestAmount, "Only investors can call this function.");
        _;
    }
}
