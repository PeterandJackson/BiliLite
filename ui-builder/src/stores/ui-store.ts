import { create } from 'zustand'

type PanelTab = 'components' | 'outline'
type RightPanelTab = 'properties' | 'styles'

interface UIStore {
  // Left panel
  leftPanelWidth: number
  leftPanelTab: PanelTab
  setLeftPanelWidth: (w: number) => void
  setLeftPanelTab: (tab: PanelTab) => void

  // Right panel
  rightPanelWidth: number
  rightPanelTab: RightPanelTab
  setRightPanelWidth: (w: number) => void
  setRightPanelTab: (tab: RightPanelTab) => void

  // Theme
  isDarkMode: boolean
  toggleDarkMode: () => void
}

export const useUIStore = create<UIStore>()((set) => ({
  leftPanelWidth: 240,
  leftPanelTab: 'components',
  setLeftPanelWidth: (w) => set({ leftPanelWidth: Math.max(180, Math.min(400, w)) }),
  setLeftPanelTab: (tab) => set({ leftPanelTab: tab }),

  rightPanelWidth: 280,
  rightPanelTab: 'properties',
  setRightPanelWidth: (w) => set({ rightPanelWidth: Math.max(220, Math.min(500, w)) }),
  setRightPanelTab: (tab) => set({ rightPanelTab: tab }),

  isDarkMode: false,
  toggleDarkMode: () => set((s) => ({ isDarkMode: !s.isDarkMode })),
}))
