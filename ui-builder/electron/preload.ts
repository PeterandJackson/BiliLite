import { contextBridge, ipcRenderer } from 'electron'

const api = {
  // File operations
  saveFile: (filePath: string, data: unknown) =>
    ipcRenderer.invoke('file:save', { filePath, data }),
  openFile: () =>
    ipcRenderer.invoke('file:open'),
  saveAsDialog: () =>
    ipcRenderer.invoke('dialog:saveAs'),

  // Export operations
  exportWrite: (outputDir: string, files: { path: string; content: string }[]) =>
    ipcRenderer.invoke('export:write', { outputDir, files }),
  openDirectoryDialog: () =>
    ipcRenderer.invoke('dialog:openDirectory'),
}

contextBridge.exposeInMainWorld('electronAPI', api)

export type ElectronAPI = typeof api
