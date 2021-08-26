import { ReactNode } from 'react'
import JSBI from 'jsbi'
import deployedContracts from './deployedContracts'

export const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

export const ETH_ADDRESS = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'

// export const ONE_SPLIT_ADRESS = '0x1d54420AdBe011C3115b72CcB876cFcBD8e3aa59'

export enum ChainId {
  MAINNET = 1,
  ROPSTEN = 3,
  RINKEBY = 4,
  GÖRLI = 5,
  KOVAN = 42,
  BSC_TESTNET = 97,
}

export type BigintIsh = JSBI | bigint | string

export type toastStatus = 'success' | 'info' | 'warning' | 'error' | undefined
export interface ToastProps {
  title?: string
  desc: string | ReactNode
  status?: toastStatus
  duration?: number
  isClosable?: boolean
}

// todo
export const CROWD_FUNDING_ADDRESSES: { [key: string]: any } = {
  [ChainId.MAINNET]: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
  [ChainId.RINKEBY]: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
  [ChainId.ROPSTEN]: '0x8A460dfD8b6e2F5CC18044129605AC46d25B2B16',
  [ChainId.BSC_TESTNET]: '0x23f53BCdBEfAE24694819C78cD6861716744b337',
}

export const NetworkContextName = 'NETWORK'

export const BIG_INT_ZERO = JSBI.BigInt(0)

// used for warning states

// exports for internal consumption
export const ZERO = JSBI.BigInt(0)
export const ONE = JSBI.BigInt(1)
export const TWO = JSBI.BigInt(2)
export const THREE = JSBI.BigInt(3)
export const FIVE = JSBI.BigInt(5)
export const TEN = JSBI.BigInt(10)
export const _100 = JSBI.BigInt(100)
export const _997 = JSBI.BigInt(997)
export const _1000 = JSBI.BigInt(1000)
export const APPROVE_NUM = JSBI.BigInt(10000000000000000000000000)

// todo
export const appPath: string[] = ['investment', 'interest', 'liquidity', 'dashboard']

export interface SubmitFuncType {
  (values: any, actions: any): void
}

// export const MAX_MINT_JT = 100000
// export const MAX_MINT_ST = 100000
// export const MAX_INVEST_JT = 100000
// export const MAX_INVEST_ST = 100000
// export const MIN_INVEST_JT = 100000
// export const MIN_INVEST_ST = 100000
// export const MIN_MINT_JT = 100000
// export const MIN_MINT_ST = 100000

export const MAX_MINT = 10000000000
export const MIN_MINT = 10
export const MAX_INVEST = 1000000000
export const MIN_INVEST = 10


