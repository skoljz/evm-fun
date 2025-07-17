# evm-fun (pump.fun analogue)

## Description

Smart contracts for launching memcoins with auto-listing Uniswap (or any Uniswap's forks DEX'es) and refund for early buyers.

## Installation

```bash
npm install
```

## Environment Variables

Add `.env` with above envs
```
UNISWAP_ROUTER=uniswap_router_address
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
