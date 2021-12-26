# Rostra Contracts

## Guide

1. Config

```bash
mv .env.example .env
```

Change the config in .env file.

2. Install dependencies

```bash
yarn
```

3. Compile contracts

```bash
npx hardhat compile
```

4. Test

```bash
yarn test
yarn testsvg
```

5. Deploy

```bash
npx hardhat run scripts/deployCrowdfunding.js --network <network_name>
```
