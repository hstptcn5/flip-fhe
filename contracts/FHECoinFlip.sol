// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, ebool, euint8, externalEuint8 } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

contract FHECoinFlip is SepoliaConfig {
    event RoundPlayed(uint256 indexed roundId, address indexed player, bytes32 resultHandle); // 1=win, 0=lose, 2=invalid
    event RandomCommitted(uint256 indexed roundId, bytes32 randomHandle);

    struct Round {
        address player;
        euint8 choice; // 0/1, приватно
        euint8 flip;   // 0/1, приватно
        euint8 result; // 1=win, 0=lose, 2=invalid
    }

    uint256 public roundsCount;
    mapping(uint256 => Round) private _rounds;
    mapping(address => uint256) public lastRoundByPlayer;

    function version() external pure returns (string memory) {
        return "FHECoinFlip/1.0.1-sepolia";
    }

    function play(externalEuint8 choiceExt, bytes calldata proof) external returns (euint8 resultCt) {
        require(proof.length > 0, "Empty proof");

        // 1) Выбор игрока
        euint8 choice = FHE.fromExternal(choiceExt, proof);

        // 2) Случайный бит контракта — корректный API
        // ebool flipB = FHE.randEbool(); // альтернативный вариант
        // euint8 flip  = FHE.select(flipB, FHE.asEuint8(1), FHE.asEuint8(0));
        euint8 flip = FHE.randEuint8(2); // равновероятно 0 или 1

        // 3) Валидация ввода: 0 или 1
        ebool isZero = FHE.eq(choice, FHE.asEuint8(0));
        ebool isOne  = FHE.eq(choice, FHE.asEuint8(1));
        ebool valid  = FHE.or(isZero, isOne);

        // 4) Сравнение и итог: 1=win, 0=lose, 2=invalid
        ebool winCmp = FHE.eq(choice, flip);
        euint8 winVal = FHE.select(winCmp, FHE.asEuint8(1), FHE.asEuint8(0));
        euint8 result = FHE.select(valid, winVal, FHE.asEuint8(2));

        // 5) ACL + публикация результата
        FHE.allowThis(choice);
        FHE.allowThis(flip);
        FHE.allowThis(result);
        FHE.allow(result, msg.sender);            // для userDecrypt(...)
        FHE.makePubliclyDecryptable(result);      // для publicDecrypt(...)

        // 6) Сохраняем раунд
        uint256 id = ++roundsCount;
        _rounds[id] = Round({ player: msg.sender, choice: choice, flip: flip, result: result });
        lastRoundByPlayer[msg.sender] = id;

        emit RoundPlayed(id, msg.sender, FHE.toBytes32(result));
        emit RandomCommitted(id, FHE.toBytes32(flip));

        return result;
    }

    function getRoundHandles(uint256 id)
        external
        view
        returns (address player, bytes32 choiceH, bytes32 flipH, bytes32 resultH)
    {
        Round storage r = _rounds[id];
        require(r.player != address(0), "No such round");
        return (r.player, FHE.toBytes32(r.choice), FHE.toBytes32(r.flip), FHE.toBytes32(r.result));
    }

    function getMyLastResultHandle() external view returns (bytes32) {
        uint256 id = lastRoundByPlayer[msg.sender];
        if (id == 0) return bytes32(0);
        return FHE.toBytes32(_rounds[id].result);
    }

    function makeRandomPublic(uint256 id) external {
        Round storage r = _rounds[id];
        require(r.player != address(0), "No such round");
        require(msg.sender == r.player, "Not your round");
        FHE.makePubliclyDecryptable(r.flip);
    }
}
