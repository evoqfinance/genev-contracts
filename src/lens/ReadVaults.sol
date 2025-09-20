// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibSort} from "../../lib/solady/src/utils/LibSort.sol";
import {IMorpho, Id, Position, Market} from "../interfaces/IMorpho.sol";
import {MarketConfig} from "../metamorpho-v1.1/libraries/PendingLib.sol";
import {IMetaMorphoV1_1 as IMetaMorpho} from "../metamorpho-v1.1/interfaces/IMetaMorphoV1_1.sol";
struct Vault {
    address vault;
    string name;
    string symbol;
    uint8 decimalsOffset;
    address asset;
    address curator;
    address owner;
    address guardian;
    uint96 fee;
    address feeRecipient;
    address skimRecipient;
    uint256 timelock;
    Id[] supplyQueue;
    Id[] withdrawQueue;
    uint256 totalSupply;
    uint256 totalAssets;
    uint256 lastTotalAssets;
}

struct VaultMarketAllocation {
    Id id;
    Position position;
    MarketConfig config;
}

struct AccrualVault {
    Vault vault;
    VaultMarketAllocation[] allocations;
}
contract ReadVaults {
    /**
     * Reads vault data for each `IMetaMorpho` entry that has an owner in `includedOwners`. For non-included ones,
     * only the `owner` field is read to save gas.
     *
     * @param metaMorphos Array of `IMetaMorpho`s to search through and (possibly) read as a vault.
     * @param includedOwners Array of owners whose vaults should be included in the returned array.
     * MUST be strictly ascending (sorted and unique).
     */
    function getAccrualVaults(
        IMorpho morpho,
        IMetaMorpho[] calldata metaMorphos,
        address[] memory includedOwners
    ) external view returns (AccrualVault[] memory) {
        require(LibSort.isSortedAndUniquified(includedOwners), "sort");

        address[] memory owners = new address[](metaMorphos.length);
        uint256 count;
        for (uint256 i; i < metaMorphos.length; i++) {
            address owner = metaMorphos[i].owner();
            if (LibSort.inSorted(includedOwners, owner)) {
                owners[i] = metaMorphos[i].owner();
                count++;
            }
        }

        AccrualVault[] memory vaults = new AccrualVault[](count);
        count = 0;
        for (uint256 i; i < metaMorphos.length; i++) {
            address owner = owners[i];
            if (owner != address(0)) {
                vaults[count] = _getAccrualVault(morpho, metaMorphos[i], owner);
                count++;
            }
        }
        return vaults;
    }

    function getAccrualVault(IMorpho morpho, IMetaMorpho metaMorpho) external view returns (AccrualVault memory) {
        return _getAccrualVault(morpho, metaMorpho, metaMorpho.owner());
    }

    function getVault(IMetaMorpho metaMorpho) external view returns (Vault memory) {
        return _getVault(metaMorpho, metaMorpho.owner());
    }

    function _getAccrualVault(
        IMorpho morpho,
        IMetaMorpho metaMorpho,
        address owner
    ) private view returns (AccrualVault memory) {
        Vault memory vault = _getVault(metaMorpho, owner);
        VaultMarketAllocation[] memory allocations = new VaultMarketAllocation[](vault.withdrawQueue.length);

        for (uint256 i; i < allocations.length; i++) {
            Id id = vault.withdrawQueue[i];
            allocations[i] = VaultMarketAllocation({
                id: id,
                position: morpho.position(id, address(metaMorpho)),
                config: metaMorpho.config(id)
            });
        }

        return AccrualVault({vault: vault, allocations: allocations});
    }

    function _getVault(IMetaMorpho metaMorpho, address owner) private view returns (Vault memory) {
        return
            Vault({
                vault: address(metaMorpho),
                name: metaMorpho.name(),
                symbol: metaMorpho.symbol(),
                decimalsOffset: metaMorpho.DECIMALS_OFFSET(),
                asset: metaMorpho.asset(),
                curator: metaMorpho.curator(),
                owner: owner,
                guardian: metaMorpho.guardian(),
                fee: metaMorpho.fee(),
                feeRecipient: metaMorpho.feeRecipient(),
                skimRecipient: metaMorpho.skimRecipient(),
                timelock: metaMorpho.timelock(),
                supplyQueue: _getSupplyQueue(metaMorpho),
                withdrawQueue: _getWithdrawQueue(metaMorpho),
                totalSupply: metaMorpho.totalSupply(),
                totalAssets: metaMorpho.totalAssets(),
                lastTotalAssets: metaMorpho.lastTotalAssets()
            });
    }

    function _getSupplyQueue(IMetaMorpho metaMorpho) private view returns (Id[] memory ids) {
        uint256 length = metaMorpho.supplyQueueLength();

        ids = new Id[](length);
        for (uint256 i; i < length; i++) ids[i] = metaMorpho.supplyQueue(i);
    }

    function _getWithdrawQueue(IMetaMorpho metaMorpho) private view returns (Id[] memory ids) {
        uint256 length = metaMorpho.withdrawQueueLength();

        ids = new Id[](length);
        for (uint256 i; i < length; i++) ids[i] = metaMorpho.withdrawQueue(i);
    }
}
