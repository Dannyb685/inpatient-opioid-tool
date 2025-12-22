import React, { useState } from 'react';
import {
    Activity,
    Calculator,
    Database,
    Home,
    Settings,
    BookOpen,
    Stethoscope
} from 'lucide-react';

import { AssessmentView } from './AssessmentView';
import { CalculatorView } from './CalculatorView';
import { ReferenceView } from './ReferenceView';
import { ToolkitView } from './ToolkitView';
import { ProtocolsView } from './ProtocolsView';
import { trackPageView } from './analytics';

// --- Shell ---

const SidebarItem = ({ active, icon: Icon, label, onClick }: { active: boolean, icon: any, label: string, onClick: () => void }) => (
    <button
        onClick={onClick}
        className={`w-full flex flex-col items-center justify-center p-3 rounded-xl transition-all mb-2 ${active
            ? 'bg-action-bg text-action shadow-sm'
            : 'text-text-tertiary hover:text-text-secondary hover:bg-surface-highlight'
            }`}
    >
        <Icon className={`w-6 h-6 mb-1 ${active ? 'stroke-2' : 'stroke-1.5'}`} />
        <span className="text-[10px] font-bold tracking-wide">{label}</span>
    </button>
);

const OpioidPrecisionApp = () => {
    const [activeTab, setActiveTab] = useState('decision');

    React.useEffect(() => {
        trackPageView(activeTab);
    }, [activeTab]);

    return (
        <div className="flex flex-col md:flex-row h-screen bg-surface-base text-text-primary font-sans overflow-hidden">
            {/* Sidebar Navigation (Desktop) */}
            <nav className="hidden md:flex w-20 bg-surface-card border-r border-border flex-col items-center py-6 z-20 flex-none">
                <div className="mb-8">
                    <div className="w-10 h-10 bg-action rounded-xl flex items-center justify-center text-white shadow-lg">
                        <Activity className="w-6 h-6" />
                    </div>
                </div>

                <div className="flex-1 w-full px-2 overflow-y-auto custom-scrollbar">
                    <SidebarItem active={activeTab === 'decision'} onClick={() => setActiveTab('decision')} icon={Home} label="Risk" />
                    <SidebarItem active={activeTab === 'moud'} onClick={() => setActiveTab('moud')} icon={Stethoscope} label="Toolkit" />
                    <SidebarItem active={activeTab === 'proto'} onClick={() => setActiveTab('proto')} icon={BookOpen} label="Protocols" />
                    <SidebarItem active={activeTab === 'calc'} onClick={() => setActiveTab('calc')} icon={Calculator} label="Dose" />
                    <SidebarItem active={activeTab === 'ref'} onClick={() => setActiveTab('ref')} icon={Database} label="Drugs" />
                </div>

                <div className="mt-auto px-2 space-y-2 flex-none">
                    <button className="w-full text-text-tertiary hover:text-text-secondary p-2"><Settings className="w-5 h-5 mx-auto" /></button>
                    <div className="w-8 h-8 rounded-full bg-surface-highlight flex items-center justify-center text-text-tertiary text-xs font-bold mx-auto">
                        DB
                    </div>
                </div>
            </nav>

            {/* Main Content Area */}
            <div className="flex-1 flex flex-col h-full bg-surface-base overflow-hidden relative">
                {/* Top Bar */}
                <header className="pt-safe md:pt-0 border-b border-border flex items-center justify-between px-4 md:px-8 bg-surface-base/80 backdrop-blur-md z-10 flex-none">
                    <div>
                        <h1 className="text-lg md:text-xl font-bold text-text-primary">
                            {activeTab === 'decision' && 'Patient Assessment'}
                            {activeTab === 'moud' && 'Assessment Toolkit'}
                            {activeTab === 'proto' && 'Clinical Protocols'}
                            {activeTab === 'calc' && 'Conversion Calculator'}
                            {activeTab === 'ref' && 'Pharmacology Reference'}
                        </h1>
                        <p className="text-[10px] md:text-xs text-text-tertiary font-medium line-clamp-1">Inpatient Opioid Management Tool</p>
                    </div>
                    <div className="md:hidden w-8 h-8 rounded-full bg-surface-highlight flex items-center justify-center text-text-tertiary text-xs font-bold">
                        DB
                    </div>
                </header>

                <main className={`flex-1 relative ${activeTab === 'decision' ? 'overflow-y-auto lg:overflow-hidden' : 'overflow-y-auto p-4 md:p-6'} pb-24 md:pb-0`}>
                    {activeTab === 'decision' && <AssessmentView />}
                    {activeTab === 'moud' && <ToolkitView />}
                    {activeTab === 'proto' && <ProtocolsView />}
                    {activeTab === 'calc' && <CalculatorView />}
                    {activeTab === 'ref' && <ReferenceView />}
                </main>

                {/* Bottom Navigation (Mobile) */}
                <div className="md:hidden fixed bottom-0 left-0 right-0 bg-surface-card/80 backdrop-blur-lg border-t border-border flex justify-around p-2 pb-safe z-30">
                    <button onClick={() => setActiveTab('decision')} className={`flex flex-col items-center p-2 rounded-lg ${activeTab === 'decision' ? 'text-action bg-action-bg' : 'text-text-tertiary'}`}>
                        <Home className="w-5 h-5" />
                        <span className="text-[9px] font-bold mt-1">Risk</span>
                    </button>
                    <button onClick={() => setActiveTab('moud')} className={`flex flex-col items-center p-2 rounded-lg ${activeTab === 'moud' ? 'text-action bg-action-bg' : 'text-text-tertiary'}`}>
                        <Stethoscope className="w-5 h-5" />
                        <span className="text-[9px] font-bold mt-1">Tools</span>
                    </button>
                    <button onClick={() => setActiveTab('proto')} className={`flex flex-col items-center p-2 rounded-lg ${activeTab === 'proto' ? 'text-action bg-action-bg' : 'text-text-tertiary'}`}>
                        <BookOpen className="w-5 h-5" />
                        <span className="text-[9px] font-bold mt-1">Proto</span>
                    </button>
                    <button onClick={() => setActiveTab('calc')} className={`flex flex-col items-center p-2 rounded-lg ${activeTab === 'calc' ? 'text-action bg-action-bg' : 'text-text-tertiary'}`}>
                        <Calculator className="w-5 h-5" />
                        <span className="text-[9px] font-bold mt-1">Dose</span>
                    </button>
                    <button onClick={() => setActiveTab('ref')} className={`flex flex-col items-center p-2 rounded-lg ${activeTab === 'ref' ? 'text-action bg-action-bg' : 'text-text-tertiary'}`}>
                        <Database className="w-5 h-5" />
                        <span className="text-[9px] font-bold mt-1">Drug</span>
                    </button>
                </div>
            </div>
        </div>
    );
};

export default OpioidPrecisionApp;
