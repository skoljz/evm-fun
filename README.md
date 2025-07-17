# evm-fun (pump.fun analogue)

## Description

Smart contracts for launching memcoins with auto-listing Uniswap (or any Uniswap's forks DEX'es) and refund for early buyers.

## Installation

```bash
npm install
```

## Environment Variables

Add `.env` with above envs for deploy
```
UNISWAP_ROUTER=uniswap_router_address
PRIVATE_KEY=your_private_key_without_0x

```

## Deployment

```bash
npx hardhat run scripts/deploy.ts --network <network>
```

## Testing

```bash
npx hardhat test
```

## Security
- Uses OpenZeppelin libraries
- Reentrancy protection
- Refund implemented via claim
