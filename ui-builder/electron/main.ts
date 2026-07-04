import { app, BrowserWindow, Menu, ipcMain, dialog } from 'electron'
import path from 'path'
import fs from 'fs'

let mainWindow: BrowserWindow | null = null

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 1024,
    minHeight: 700,
    title: 'UI Builder',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false,
    },
  })

  if (process.env.VITE_DEV_SERVER_URL) {
    mainWindow.loadURL(process.env.VITE_DEV_SERVER_URL)
  } else {
    mainWindow.loadFile(path.join(__dirname, '../dist/index.html'))
  }

  mainWindow.on('closed', () => {
    mainWindow = null
  })
}

// ── IPC Handlers ──────────────────────────────────────────────

// File: Save project
ipcMain.handle('file:save', async (_event, { filePath, data }) => {
  try {
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf-8')
    return { success: true }
  } catch (e: any) {
    return { success: false, error: e.message }
  }
})

// File: Open project
ipcMain.handle('file:open', async () => {
  const result = await dialog.showOpenDialog(mainWindow!, {
    title: 'Open Project',
    filters: [{ name: 'UI Builder Project', extensions: ['uibuilder'] }],
    properties: ['openFile'],
  })
  if (result.canceled || result.filePaths.length === 0) {
    return { success: false, canceled: true }
  }
  try {
    const content = fs.readFileSync(result.filePaths[0], 'utf-8')
    return { success: true, data: JSON.parse(content), filePath: result.filePaths[0] }
  } catch (e: any) {
    return { success: false, error: e.message }
  }
})

// File: Save As dialog
ipcMain.handle('dialog:saveAs', async () => {
  const result = await dialog.showSaveDialog(mainWindow!, {
    title: 'Save Project As',
    filters: [{ name: 'UI Builder Project', extensions: ['uibuilder'] }],
  })
  if (result.canceled || !result.filePath) {
    return { success: false, canceled: true }
  }
  return { success: true, filePath: result.filePath }
})

// Export: Write output files
ipcMain.handle('export:write', async (_event, { outputDir, files }) => {
  try {
    for (const file of files) {
      const fullPath = path.join(outputDir, file.path)
      const dir = path.dirname(fullPath)
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true })
      }
      fs.writeFileSync(fullPath, file.content, 'utf-8')
    }
    return { success: true }
  } catch (e: any) {
    return { success: false, error: e.message }
  }
})

// Export: Choose directory
ipcMain.handle('dialog:openDirectory', async () => {
  const result = await dialog.showOpenDialog(mainWindow!, {
    title: 'Select Export Directory',
    properties: ['openDirectory', 'createDirectory'],
  })
  if (result.canceled || result.filePaths.length === 0) {
    return { success: false, canceled: true }
  }
  return { success: true, dirPath: result.filePaths[0] }
})

// ── App lifecycle ──────────────────────────────────────────────

app.whenReady().then(() => {
  createWindow()

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow()
    }
  })
})

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit()
  }
})
