// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import {AggregatorV3Interface} from "../interfaces/AggregatorV3Interface.sol";
import {IFeedProxy} from "./interfaces/IFeedProxy.sol";

/// @title OraklToChainlinkAdapter
/// @notice Adapter to make Orakl Network feeds compatible with Chainlink interface
/// @dev This adapter wraps Orakl Network FeedProxy to implement AggregatorV3Interface
contract OraklToChainlinkAdapter is AggregatorV3Interface {
    IFeedProxy public immutable oraklFeed;
    string public override description;
    uint256 public override version = 1;

    error InvalidOraklFeed();
    error NegativeAnswer();

    /// @notice Constructor
    /// @param _oraklFeed Address of the Orakl Network FeedProxy
    /// @param _description Description of the feed (e.g., "BTC/USD")
    constructor(address _oraklFeed, string memory _description) {
        if (_oraklFeed == address(0)) revert InvalidOraklFeed();
        oraklFeed = IFeedProxy(_oraklFeed);
        description = _description;
    }

    /// @notice Get the latest round data from Orakl Network feed
    /// @return roundId The round ID
    /// @return answer The price data
    /// @return startedAt Always 0 (not provided by Orakl)
    /// @return updatedAt Timestamp when the data was last updated
    /// @return answeredInRound The round ID (same as roundId)
    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        (uint80 id, int256 price, uint256 timestamp) = oraklFeed.latestRoundData();

        if (price < 0) revert NegativeAnswer();

        return (
            id, // roundId
            price, // answer
            0, // startedAt (not provided by Orakl)
            timestamp, // updatedAt
            id // answeredInRound
        );
    }

    /// @notice Get round data for a specific round ID
    /// @param _roundId The round ID to query
    /// @return roundId The round ID
    /// @return answer The price data
    /// @return startedAt Always 0 (not provided by Orakl)
    /// @return updatedAt Timestamp when the data was last updated
    /// @return answeredInRound The round ID (same as roundId)
    function getRoundData(
        uint80 _roundId
    )
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        (uint80 id, int256 price, uint256 timestamp) = oraklFeed.getRoundData(uint64(_roundId));

        if (price < 0) revert NegativeAnswer();

        return (
            id, // roundId
            price, // answer
            0, // startedAt (not provided by Orakl)
            timestamp, // updatedAt
            id // answeredInRound
        );
    }

    /// @notice Get the number of decimals for the price data
    /// @return The number of decimals
    function decimals() external view override returns (uint8) {
        return oraklFeed.decimals();
    }
}
