import { App, Plugin, PluginSettingTab, Setting, WorkspaceLeaf, ItemView } from 'obsidian';
import * as React from 'react';
import { createRoot, Root } from 'react-dom/client';
import OpioidPrecisionApp from './src/OpioidPrecisionApp';

const VIEW_TYPE_OPIOID = "opioid-precision-tool-view";

class OpioidView extends ItemView {
    root: Root | null = null;

    constructor(leaf: WorkspaceLeaf) {
        super(leaf);
    }

    getViewType() {
        return VIEW_TYPE_OPIOID;
    }

    getDisplayText() {
        return "Opioid Precision Tool";
    }

    async onOpen() {
        const container = this.containerEl.children[1];
        container.empty();
        container.addClass('opioid-tool-container');

        this.root = createRoot(container);
        this.root.render(
            React.createElement(React.StrictMode, null,
                React.createElement(OpioidPrecisionApp, null)
            )
        );
    }

    async onClose() {
        if (this.root) {
            this.root.unmount();
        }
    }
}

export default class OpioidPlugin extends Plugin {
    async onload() {
        this.registerView(
            VIEW_TYPE_OPIOID,
            (leaf) => new OpioidView(leaf)
        );

        this.addRibbonIcon('activity', 'Open Inpatient Opioid Tool', (evt: MouseEvent) => {
            this.activateView();
        });

        this.addCommand({
            id: 'open-opioid-tool-view',
            name: 'Open Opioid Precision Tool',
            callback: () => {
                this.activateView();
            }
        });
    }

    onunload() {

    }

    async activateView() {
        const { workspace } = this.app;

        let leaf: WorkspaceLeaf | null = null;
        const leaves = workspace.getLeavesOfType(VIEW_TYPE_OPIOID);

        if (leaves.length > 0) {
            // A leaf with our view already exists, use that
            leaf = leaves[0];
        } else {
            // Our view could not be found in the workspace, create a new leaf
            // in the right sidebar for now, or main. 
            // Usually main is improved for full apps.
            leaf = workspace.getLeaf('tab');
            await leaf.setViewState({ type: VIEW_TYPE_OPIOID, active: true });
        }

        // "Reveal" the leaf in case it is in a collapsed sidebar
        workspace.revealLeaf(leaf);
    }
}
