// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import {AggregatorV3Interface} from "../interfaces/AggregatorV3Interface.sol";
import {IFeedRouter} from "./interfaces/IFeedRouter.sol";

/// @title OraklRouterAdapter
/// @notice Adapter using Orakl FeedRouter for multiple feeds
/// @dev This adapter wraps Orakl Network FeedRouter to implement AggregatorV3Interface for a specific feed
contract OraklRouterAdapter is AggregatorV3Interface {
    IFeedRouter public immutable oraklRouter;
    string public feedName;
    uint256 public override version = 1;

    error InvalidOraklRouter();
    error NegativeAnswer();

    /// @notice Constructor
    /// @param _oraklRouter Address of the Orakl Network FeedRouter
    /// @param _feedName Name of the feed (e.g., "BTC-USDT")
    constructor(address _oraklRouter, string memory _feedName) {
        if (_oraklRouter == address(0)) revert InvalidOraklRouter();
        oraklRouter = IFeedRouter(_oraklRouter);
        feedName = _feedName;
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
        (uint80 id, int256 price, uint256 timestamp) = oraklRouter.latestRoundData(feedName);

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
        (uint80 id, int256 price, uint256 timestamp) = oraklRouter.getRoundData(feedName, uint64(_roundId));

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
        return oraklRouter.decimals(feedName);
    }

    /// @notice Get the description of the feed
    /// @return The feed description
    function description() external view override returns (string memory) {
        return string(abi.encodePacked("Orakl Network Feed: ", feedName));
    }

    /// @notice Get the current feed address for this feed name
    /// @return The feed address
    function getCurrentFeed() external view returns (address) {
        return oraklRouter.feedToProxies(feedName);
    }
}
