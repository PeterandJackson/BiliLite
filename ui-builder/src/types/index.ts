export * from './component'
export * from './canvas'

// Global Electron API type
import type { ElectronAPI } from '../../electron/preload'

declare global {
  interface Window {
    electronAPI: ElectronAPI
  }
}
