# 🎲 ZAMA FHE Coin Flip (FHEVM, Sepolia)

**Private “Heads or Tails” on-chain** built with Zama’s FHEVM.  
A player encrypts their choice (`0 = Heads`, `1 = Tails`) on the client using the **Relayer SDK**.  
The contract generates its own encrypted random bit, compares privately on-chain, and exposes **only the result** (win/lose) for public decryption. Optionally, the player can reveal the contract’s flip.

> **Deployed (Sepolia):** `0xd22E7A123168C63f5efEA75d197faCbd0022791C`  
> **Frontend:** single-file `index.html` using `@zama-fhe/relayer-sdk` + `ethers v6`.

---

## ✨ Features

- **End-to-end privacy:** player’s choice and contract’s flip are encrypted (`euint8`); only the result is public.
- **On-chain randomness (FHE):** contract draws a private random bit and compares homomorphically.
- **One-click UX:** frontend encrypts inputs, calls `play(...)`, then **publicDecrypt** the result.
- **Optional reveal:** player can reveal the contract’s flip (`makeRandomPublic`) for transparency.
- **No deprecated libs:** uses only Zama’s **official** Solidity library and **Relayer SDK**.

---

## 📦 Contract

Solidity uses only:
```solidity
import { FHE, ebool, euint8, externalEuint8 } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";


Main functions

play(externalEuint8 choiceExt, bytes proof) returns (euint8 resultCt)
Encrypt, validate (0/1), flip privately, compare, publish result (1 = win, 0 = lose, 2 = invalid).

getMyLastResultHandle() view returns (bytes32)
Handle for last result (public-decryptable).

getRoundHandles(uint256 id) view returns (address player, bytes32 choiceH, bytes32 flipH, bytes32 resultH)
Return all ciphertext handles (decryption obeys ACL).

makeRandomPublic(uint256 id)
Mark contract’s flip as publicly decryptable (player-only).

Events

RoundPlayed(uint256 roundId, address player, bytes32 resultHandle)

RandomCommitted(uint256 roundId, bytes32 randomHandle)

🖥️ Frontend

Single-file index.html with:

@zama-fhe/relayer-sdk (official, CDNs)

ethers@6

Connect MetaMask → encrypt choice → play(...) → publicDecrypt(result)

Optional “Reveal Contract Flip” (makes flip public and decrypts it)

Update the contract address in the file if you redeploy.

🚀 Quickstart
Prerequisites

Node.js 18+

MetaMask on Sepolia

Some Sepolia ETH for gas

1) Clone & Install
git clone https://github.com/<your-username>/<your-repo>.git
cd <your-repo>
npm i -D hardhat @fhevm/solidity ethers dotenv
npm i @zama-fhe/relayer-sdk


If you only need the frontend, you can keep just index.html and serve it statically.

2) Compile / Deploy (optional)

If you want to deploy your own copy:

npx hardhat compile
# write a small deploy script or use hardhat console to deploy FHECoinFlip


Then put your new address into index.html:

const CONTRACT_ADDRESS = "0xYourNewAddress";

3) Run the Frontend (static server)

Browsers may require serving over HTTP due to COOP/COEP and module imports:

npx http-server -c-1 -p 8080
# or
npx serve .
# or
npx vite preview


Open http://localhost:8080 (or the port shown).

🔑 How it works (data flow)

Encrypt input:
Frontend uses createInstance from @zama-fhe/relayer-sdk and calls:

Buffer API: const buf = instance.createEncryptedInput(contractAddress, userAddress);

buf.add8(choice); const { handles, inputProof } = await buf.encrypt();

Submit tx:
Call play(choiceHandle, proof) with ethers.Contract.

Public decrypt:
Contract marks result as FHE.makePubliclyDecryptable(result).
Frontend does instance.publicDecrypt([resultHandle]) and renders 0/1/2.

Optional reveal:
makeRandomPublic(roundId), then publicDecrypt([flipHandle]).

🛡️ Security & Privacy Notes

Avoid FHE ops in view/pure functions (we only return handles there).

Use proper ACL:

FHE.allowThis(...) for storage reuse

FHE.allow(result, msg.sender) for private userDecrypt if needed

FHE.makePubliclyDecryptable(result) for global readability (used for UX)

euint8 supports arithmetic/comparison; do not use arithmetic on euint256/eaddress.

📥 Download

Download ZIP (GitHub)
Replace with your repo slug:
https://github.com/<your-username>/<your-repo>/archive/refs/heads/main.zip

Releases page (recommended)
https://github.com/<your-username>/<your-repo>/releases/latest


📝 License

MIT — see LICENSE.
