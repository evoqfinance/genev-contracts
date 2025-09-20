// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {Morpho} from "../src/Morpho.sol";
import {AdaptiveCurveIrm} from "../src/irm/adaptive-curve-irm/AdaptiveCurveIrm.sol";

import {OracleMock} from "../src/mocks/OracleMock.sol";
import {MarketParams, Id} from "../src/interfaces/IMorpho.sol";
import {MarketParamsLib} from "../src/libraries/MarketParamsLib.sol";
import {ORACLE_PRICE_SCALE} from "../src/libraries/ConstantsLib.sol";
import {BaseConfig} from "../config/BaseConfig.sol";
import {ReadVaults} from "../src/lens/ReadVaults.sol";
import {MorphoChainlinkOracleV2Factory} from "../src/oracles/MorphoChainlinkOracleV2Factory.sol";
import {OraklAdapterFactory} from "../src/oracles/orakl-adapter/OraklAdapterFactory.sol";
import {OraklRouterAdapter} from "../src/oracles/orakl-adapter/OraklRouterAdapter.sol";
import {IMorphoChainlinkOracleV2} from "../src/oracles/interfaces/IMorphoChainlinkOracleV2.sol";
import {AggregatorV3Interface} from "../src/oracles/libraries/ChainlinkDataFeedLib.sol";
import {IERC4626} from "../src/oracles/interfaces/IERC4626.sol";

/// @title DeployMorpho
/// @notice Script to deploy the Morpho contract
/// @author Morpho Labs
contract DeployMorpho is Script, BaseConfig {
    using MarketParamsLib for MarketParams;

    /// @notice The address that will be set as the owner of the Morpho contract
    address public owner;

    /// @notice The deployed MorphoChainlinkOracleV2Factory
    MorphoChainlinkOracleV2Factory public morphoOracleFactory;

    /// @notice The deployed OraklAdapterFactory
    OraklAdapterFactory public oraklAdapterFactory;

    /// @notice The address of the Orakl Network FeedRouter
    address public oraklRouterAddress;

    function setUp() public {
        // Set the owner address - you can modify this or set it via environment variable
        owner = vm.envOr("MORPHO_OWNER", address(msg.sender));
        oraklRouterAddress = vm.envOr("ORAKL_ROUTER_ADDRESS", address(0x653078F0D3a230416A59aA6486466470Db0190A2));
        // Ensure owner is not zero address
        require(owner != address(0), "Owner cannot be zero address");
    }

    /// @notice Creates a new market with the specified parameters
    /// @param morpho The Morpho contract instance
    /// @param loanToken The address of the loan token
    /// @param collateralToken The address of the collateral token
    /// @param oracle The address of the oracle
    /// @param irm The address of the interest rate model
    /// @param lltv The loan-to-value ratio (in WAD)
    function createMarket(
        Morpho morpho,
        address loanToken,
        address collateralToken,
        address oracle,
        address irm,
        uint256 lltv
    ) internal {
        MarketParams memory marketParams = MarketParams({
            loanToken: loanToken,
            collateralToken: collateralToken,
            oracle: oracle,
            irm: irm,
            lltv: lltv
        });

        // Only enable IRM and LLTV if they haven't been enabled yet
        if (!morpho.isIrmEnabled(irm)) {
            morpho.enableIrm(irm);
        }
        if (!morpho.isLltvEnabled(lltv)) {
            morpho.enableLltv(lltv);
        }

        morpho.createMarket(marketParams);
    }

    /// @notice Deploys the oracle factories
    function deployOracleFactories() internal {
        morphoOracleFactory = new MorphoChainlinkOracleV2Factory();
        oraklAdapterFactory = new OraklAdapterFactory();

        console.log("MorphoChainlinkOracleV2Factory deployed at:", address(morphoOracleFactory));
        console.log("OraklAdapterFactory deployed at:", address(oraklAdapterFactory));
    }

    /// @notice Creates an OraklRouterAdapter for a specific feed
    /// @param oraklRouter The address of the Orakl Network FeedRouter
    /// @param feedName The name of the feed (e.g., "WKAIA-USDT")
    /// @param salt A unique salt for deterministic deployment
    /// @return adapter The deployed OraklRouterAdapter
    function deployOraklRouterAdapter(
        address oraklRouter,
        string memory feedName,
        bytes32 salt
    ) internal returns (OraklRouterAdapter adapter) {
        adapter = oraklAdapterFactory.createOraklRouterAdapter(oraklRouter, feedName, salt);
        console.log("OraklRouterAdapter deployed at:", address(adapter));
        console.log("Feed name:", feedName);
        return adapter;
    }

    /// @notice Deploys a MorphoChainlinkOracleV2 using the factory with Orakl adapters
    /// @param baseToken The base token address (collateral token)
    /// @param quoteToken The quote token address (loan token)
    /// @param baseTokenDecimals The decimals of the base token
    /// @param quoteTokenDecimals The decimals of the quote token
    /// @param baseFeedAdapter The Orakl adapter for the base token feed
    /// @param quoteFeedAdapter The Orakl adapter for the quote token feed
    /// @param salt A unique salt for deterministic deployment
    /// @return oracle The deployed MorphoChainlinkOracleV2 oracle
    function deployMorphoOracleWithOraklAdapters(
        address baseToken,
        address quoteToken,
        uint256 baseTokenDecimals,
        uint256 quoteTokenDecimals,
        AggregatorV3Interface baseFeedAdapter,
        AggregatorV3Interface quoteFeedAdapter,
        bytes32 salt
    ) internal returns (IMorphoChainlinkOracleV2 oracle) {
        oracle = morphoOracleFactory.createMorphoChainlinkOracleV2(
            IERC4626(address(0)), // baseVault - no vault for base token
            1, // baseVaultConversionSample - not used when no vault
            baseFeedAdapter, // baseFeed1
            AggregatorV3Interface(address(0)), // baseFeed2 - not needed
            baseTokenDecimals,
            IERC4626(address(0)), // quoteVault - no vault for quote token
            1, // quoteVaultConversionSample - not used when no vault
            quoteFeedAdapter, // quoteFeed1
            AggregatorV3Interface(address(0)), // quoteFeed2 - not needed
            quoteTokenDecimals,
            salt
        );

        console.log("MorphoChainlinkOracleV2 deployed at:", address(oracle));
        console.log("Base token:", baseToken);
        console.log("Quote token:", quoteToken);
        return oracle;
    }

    /// @notice Deploys complete oracle setup for a market using Orakl Network
    /// @param baseToken The base token address (collateral token)
    /// @param quoteToken The quote token address (loan token)
    /// @param baseTokenDecimals The decimals of the base token
    /// @param quoteTokenDecimals The decimals of the quote token
    /// @param oraklRouter The address of the Orakl Network FeedRouter
    /// @param baseFeedName The name of the base token feed (e.g., "WKAIA-USDT")
    /// @param quoteFeedName The name of the quote token feed (e.g., "USDT-USD")
    /// @param marketSalt A unique salt for this market's oracle deployment
    /// @return oracle The deployed MorphoChainlinkOracleV2 oracle
    function deployOracleForMarket(
        address baseToken,
        address quoteToken,
        uint256 baseTokenDecimals,
        uint256 quoteTokenDecimals,
        address oraklRouter,
        string memory baseFeedName,
        string memory quoteFeedName,
        bytes32 marketSalt
    ) internal returns (IMorphoChainlinkOracleV2 oracle) {
        // Deploy Orakl adapters for both tokens
        bytes32 baseAdapterSalt = keccak256(abi.encodePacked(marketSalt, "base"));
        bytes32 quoteAdapterSalt = keccak256(abi.encodePacked(marketSalt, "quote"));

        OraklRouterAdapter baseAdapter;
        if (keccak256(abi.encodePacked(baseFeedName)) != keccak256(abi.encodePacked(""))) {
            baseAdapter = deployOraklRouterAdapter(oraklRouter, baseFeedName, baseAdapterSalt);
        } else {
            baseAdapter = OraklRouterAdapter(address(0));
        }

        OraklRouterAdapter quoteAdapter;
        if (keccak256(abi.encodePacked(quoteFeedName)) != keccak256(abi.encodePacked(""))) {
            quoteAdapter = deployOraklRouterAdapter(oraklRouter, quoteFeedName, quoteAdapterSalt);
        } else {
            quoteAdapter = OraklRouterAdapter(address(0));
        }

        // Deploy Morpho oracle using the adapters
        oracle = deployMorphoOracleWithOraklAdapters(
            baseToken,
            quoteToken,
            baseTokenDecimals,
            quoteTokenDecimals,
            baseAdapter,
            quoteAdapter,
            marketSalt
        );

        console.log("Complete oracle setup deployed for market (base/quote):", baseToken, "/", quoteToken);
        return oracle;
    }

    function run() public {
        vm.startBroadcast();

        Morpho morpho = new Morpho(owner);
        AdaptiveCurveIrm adaptiveCurveIrm = new AdaptiveCurveIrm(address(morpho));

        // Deploy oracle factories
        deployOracleFactories();

        // Example: Deploy oracles using Orakl Network (commented out as it requires actual Orakl router)
        // Uncomment and configure these when you have the actual Orakl router address and feed names

        if (oraklRouterAddress != address(0)) {
            // Deploy oracle for WKAIA-USDT market using Orakl Network
            IMorphoChainlinkOracleV2 oracleWKAIA_USDT_Orakl = deployOracleForMarket(
                WKAIA, // base token (collateral)
                USDT, // quote token (loan)
                18, // WKAIA decimals
                6, // USDT decimals
                oraklRouterAddress,
                "KAIA-KRW", // base feed name
                "USDT-KRW", // quote feed name
                keccak256(abi.encodePacked("KAIA-USDT-MARKET"))
            );

            createMarket(
                morpho,
                USDT, // loan token
                WKAIA, // collateral token
                address(oracleWKAIA_USDT_Orakl),
                address(adaptiveCurveIrm),
                0.8e18 // LLTV
            );

            // Deploy oracle for USDT-WKAIA market using Orakl Network
            IMorphoChainlinkOracleV2 oracleUSDT_WKAIA_Orakl = deployOracleForMarket(
                USDT, // base token (collateral)
                WKAIA, // quote token (loan)
                6, // USDT decimals
                18, // WKAIA decimals
                oraklRouterAddress,
                "USDT-KRW", // base feed name
                "KAIA-KRW", // quote feed name
                keccak256(abi.encodePacked("USDT-KAIA-MARKET"))
            );

            createMarket(
                morpho,
                WKAIA, // loan token
                USDT, // collateral token
                address(oracleUSDT_WKAIA_Orakl),
                address(adaptiveCurveIrm),
                0.8e18 // LLTV
            );
        } else {
            console.log("ORAKL_ROUTER_ADDRESS not set. Set it to deploy oracles with Orakl Network.");
            console.log("Example: export ORAKL_ROUTER_ADDRESS=0x...");
        }

        /*
        // WKAIA-USDT (collateral-loan)
        OracleMock oracleWKAIA_USDT = new OracleMock();
        oracleWKAIA_USDT.setPrice((ORACLE_PRICE_SCALE * 1e6) / 1e18); // 36 + loan token decimals - collateral token decimals
        createMarket(
            morpho,
            USDT, // loan token
            WKAIA, // collateral token
            address(oracleWKAIA_USDT),
            address(adaptiveCurveIrm),
            0.8e18 // LLTV
        );

        // USDT-WKAIA (collateral-loan)
        OracleMock oracleUSDT_WKAIA = new OracleMock();
        oracleUSDT_WKAIA.setPrice((ORACLE_PRICE_SCALE * 1e18) / 1e6); // 36 + loan token decimals - collateral token decimals
        createMarket(
            morpho,
            WKAIA, // loan token
            USDT, // collateral token
            address(oracleUSDT_WKAIA),
            address(adaptiveCurveIrm),
            0.8e18 // LLTV
        );
        */

        vm.stopBroadcast();
    }
}
