// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface ITrophies {
    struct Stake {
        uint256[] tokenIds;
        uint256 timestamp;
    }

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external returns(uint256[] memory);

    function getStake(address _user) external returns(Stake memory);
}

contract Raffles is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    struct Raffle {
        address[] entries;
        address[] winners;
        uint256 minimumTrophyId;
        uint256 timestamp;
        uint256 duration;
    }

    Raffle[] public raffles;
    address trophiesContract;

    // trophy eligibility
    uint256 diamondEligibility;
    uint256 goldEligibility;
    uint256 silverEligibility;
    uint256 bronzeEligibility;

    // trophy ids
    uint256 diamondTrophyId;
    uint256 goldTrophyId;
    uint256 silverTrophyId;
    uint256 bronzeTrophyId;

    function initialize() initializer public {
        __Ownable_init();
        trophiesContract = 0x717C6dD66Be92E979001aee2eE169aAA8D6D4361;
        // trophies
        diamondEligibility = 25;
        goldEligibility = 10;
        silverEligibility = 5;
        bronzeEligibility = 1;
        diamondTrophyId  = 4;
        goldTrophyId = 3;
        silverTrophyId = 2;
        bronzeTrophyId = 1;
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

    function setTrophiesContract(address _trophiesContract) public onlyOwner {
        trophiesContract = _trophiesContract;
    }

    function getRaffle(uint256 _raffleIndex) public view returns(Raffle memory) {
        return raffles[_raffleIndex];
    }

    function startNewRaffle(uint256 _minimumTrophyId, uint256 _duration) public onlyOwner {
        address[] memory newEntries = new address[](0);
        address[] memory winners = new address[](0);
        raffles.push(Raffle(
            newEntries,
            winners,
            _minimumTrophyId,
            block.timestamp,
            _duration
        ));
    }

    function  checkStakedTokens(uint256 _raffleIndex) internal {
        Raffle memory raffle = raffles[_raffleIndex];
        uint256[] memory stakedTokenIds = ITrophies(trophiesContract).getStake(msg.sender).tokenIds;
        uint256 minimumStakeNeeded = 0;

        if (raffle.minimumTrophyId == diamondTrophyId) {
            minimumStakeNeeded = diamondEligibility;
        } else if (raffle.minimumTrophyId == goldTrophyId) {
            minimumStakeNeeded = goldEligibility;
        } else if (raffle.minimumTrophyId == silverTrophyId) {
            minimumStakeNeeded = silverEligibility;
        } else {
            minimumStakeNeeded = bronzeEligibility;
        }

        require(stakedTokenIds.length >= minimumStakeNeeded, "You do not have enough staked to enter this raffle!");
    }

    function checkMinimumTrophy(uint256 _raffleIndex, uint256 _maxTrophyId) internal {
        Raffle memory raffle = raffles[_raffleIndex];
        ITrophies trophies = ITrophies(trophiesContract);
        uint256 minimumTrophyId = raffle.minimumTrophyId;
        uint256 numOfTrophiesToCheck = (_maxTrophyId - minimumTrophyId) + 1;
        uint256[] memory trophyIdsToCheck = new uint256[](numOfTrophiesToCheck);
        address[] memory addressesToCheck = new address[](numOfTrophiesToCheck);
        uint256 addressesToCheckIndex = 0;
        uint256 trophiesToCheckIndex = 0;
        for (uint256 i = minimumTrophyId; i < _maxTrophyId + 1; i++) {
            addressesToCheck[addressesToCheckIndex] = msg.sender;
            addressesToCheckIndex++;
        }

        for (uint256 i = minimumTrophyId; i < _maxTrophyId + 1; i++) {
            trophyIdsToCheck[trophiesToCheckIndex] = i;
            trophiesToCheckIndex++;
        }

        uint256[] memory balances = trophies.balanceOfBatch(addressesToCheck, trophyIdsToCheck);
        bool userHasMinimumTrophy = false;
        for (uint256 i = 0; i < balances.length; i++) {
            if (balances[i] > 0) {
                userHasMinimumTrophy = true;
                break;
            }
        }
        require(userHasMinimumTrophy, "You do not have the minimum trophy needed to participate in this raffle!");
    }

    function enterRaffle(uint256 _raffleIndex, uint256 _maxTrophyId) public {
        Raffle memory raffle = raffles[_raffleIndex];
        // check if raffle is active
        require(raffle.timestamp + raffle.duration > block.timestamp, "Raffle is not active!");
        checkMinimumTrophy(_raffleIndex, _maxTrophyId);
        checkStakedTokens(_raffleIndex);

        bool hasUserEnteredBefore = false;
        for (uint256 i = 0; i < raffles[_raffleIndex].entries.length; i++) {
            if (raffles[_raffleIndex].entries[i] == msg.sender) {
                hasUserEnteredBefore = true;
                break;
            }
        }
        require(!hasUserEnteredBefore, "You have already entered this raffle!");
        raffles[_raffleIndex].entries.push(msg.sender);
    }

    function setWinners(uint256 _raffleIndex, address[] calldata winners) public onlyOwner {
        raffles[_raffleIndex].winners = winners;
    }
}