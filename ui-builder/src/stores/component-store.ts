import { create } from 'zustand'
import { temporal } from 'zundo'
import { nanoid } from 'nanoid'
import type { ComponentInstance, StyleProperties, ProjectData } from '@/types'
import { getComponentDefinition } from '@/core/component-registry'

interface ComponentStore {
  components: Record<string, ComponentInstance>
  rootIds: string[]
  selectedIds: Set<string>
  currentFilePath: string | null
  isDirty: boolean

  // Actions
  addComponent: (parentId: string | null, index: number, type: string) => string | null
  removeComponent: (id: string) => void
  moveComponent: (id: string, newParentId: string | null, newIndex: number) => void
  updateComponentProps: (id: string, props: Record<string, unknown>) => void
  updateComponentStyles: (id: string, styles: StyleProperties) => void
  setSelection: (ids: string[]) => void
  clearSelection: () => void
  addToSelection: (id: string) => void
  removeFromSelection: (id: string) => void
  selectAll: () => void

  // Project
  loadProject: (data: ProjectData) => void
  getProjectData: () => ProjectData
  setFilePath: (path: string | null) => void
  markClean: () => void
}

export const useComponentStore = create<ComponentStore>()(
  temporal(
    (set, get) => ({
      components: {},
      rootIds: [],
      selectedIds: new Set<string>(),
      currentFilePath: null,
      isDirty: false,

      addComponent: (parentId, index, type) => {
        const def = getComponentDefinition(type)
        if (!def) return null

        const id = nanoid(8)
        const instance: ComponentInstance = {
          id,
          type,
          props: { ...def.defaultProps },
          styles: { ...def.defaultStyles },
          children: [],
          parentId,
        }

        set((state) => {
          const components = { ...state.components, [id]: instance }
          let roots = [...state.rootIds]

          if (parentId && components[parentId]) {
            const parent = { ...components[parentId] }
            const children = [...parent.children]
            const idx = Math.min(index, children.length)
            children.splice(idx, 0, id)
            parent.children = children
            components[parentId] = parent
          } else {
            const idx = Math.min(index, roots.length)
            roots.splice(idx, 0, id)
          }

          return { components, rootIds: roots, selectedIds: new Set([id]), isDirty: true }
        })

        return id
      },

      removeComponent: (id) => {
        set((state) => {
          const components = { ...state.components }
          const toRemove = new Set<string>()

          // Recursively collect all descendants
          const collectDescendants = (compId: string) => {
            toRemove.add(compId)
            const comp = components[compId]
            if (comp) {
              comp.children.forEach(childId => collectDescendants(childId))
            }
          }
          collectDescendants(id)

          // Remove from parent
          const comp = components[id]
          if (comp?.parentId && components[comp.parentId]) {
            const parent = { ...components[comp.parentId] }
            parent.children = parent.children.filter(c => c !== id)
            components[comp.parentId] = parent
          }

          // Delete all collected IDs
          toRemove.forEach(cid => delete components[cid])

          // Update rootIds
          const roots = state.rootIds.filter(rid => !toRemove.has(rid))

          // Update selection
          const selectedIds = new Set([...state.selectedIds].filter(sid => !toRemove.has(sid)))

          return { components, rootIds: roots, selectedIds, isDirty: true }
        })
      },

      moveComponent: (id, newParentId, newIndex) => {
        set((state) => {
          const components = { ...state.components }
          const comp = components[id]
          if (!comp) return state

          // Remove from old parent
          if (comp.parentId && components[comp.parentId]) {
            const oldParent = { ...components[comp.parentId] }
            oldParent.children = oldParent.children.filter(c => c !== id)
            components[comp.parentId] = oldParent
          }

          let roots = [...state.rootIds]
          // Also remove from rootIds if it was there
          roots = roots.filter(rid => rid !== id)

          // Add to new parent
          if (newParentId && components[newParentId]) {
            const newParent = { ...components[newParentId] }
            const children = [...newParent.children]
            children.splice(newIndex, 0, id)
            newParent.children = children
            components[newParentId] = newParent
            components[id] = { ...comp, parentId: newParentId }
          } else {
            roots.splice(newIndex, 0, id)
            components[id] = { ...comp, parentId: null }
          }

          return { components, rootIds: roots, isDirty: true }
        })
      },

      updateComponentProps: (id, props) => {
        set((state) => {
          const comp = state.components[id]
          if (!comp) return state
          return {
            components: {
              ...state.components,
              [id]: { ...comp, props: { ...comp.props, ...props } },
            },
            isDirty: true,
          }
        })
      },

      updateComponentStyles: (id, styles) => {
        set((state) => {
          const comp = state.components[id]
          if (!comp) return state
          return {
            components: {
              ...state.components,
              [id]: { ...comp, styles: { ...comp.styles, ...styles } },
            },
            isDirty: true,
          }
        })
      },

      setSelection: (ids) => {
        set({ selectedIds: new Set(ids) })
      },

      clearSelection: () => {
        set({ selectedIds: new Set() })
      },

      addToSelection: (id) => {
        set((state) => {
          const next = new Set(state.selectedIds)
          next.add(id)
          return { selectedIds: next }
        })
      },

      removeFromSelection: (id) => {
        set((state) => {
          const next = new Set(state.selectedIds)
          next.delete(id)
          return { selectedIds: next }
        })
      },

      selectAll: () => {
        set((state) => ({
          selectedIds: new Set(Object.keys(state.components)),
        }))
      },

      loadProject: (data) => {
        set({
          components: data.components,
          rootIds: data.pages[0]?.rootIds ?? [],
          selectedIds: new Set(),
          isDirty: false,
        })
      },

      getProjectData: () => {
        const state = get()
        return {
          version: '1.0.0',
          metadata: {
            name: 'Untitled Project',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            canvasWidth: 1440,
            canvasHeight: 900,
          },
          pages: [
            {
              id: 'page-1',
              name: 'Page 1',
              route: '/',
              rootIds: state.rootIds,
            },
          ],
          components: state.components,
        }
      },

      setFilePath: (path) => {
        set({ currentFilePath: path })
      },

      markClean: () => {
        set({ isDirty: false })
      },
    }),
    {
      limit: 100,
      partialize: (state) => ({
        components: state.components,
        rootIds: state.rootIds,
      }),
    }
  )
)
