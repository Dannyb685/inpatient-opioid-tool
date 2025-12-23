import React, { useState, useEffect } from 'react';
import {
    Activity,
    Calculator,
    Database,
    Home,
    Settings,
    BookOpen,
    Stethoscope,
    Moon,
    Sun,
    ClipboardCheck
} from 'lucide-react';

import { AssessmentView } from './AssessmentView';
import { CalculatorView } from './CalculatorView';
import { ReferenceView } from './ReferenceView';
import { ToolkitView } from './ToolkitView';
import { ProtocolsView } from './ProtocolsView';
import { SBIRTView } from './SBIRTView';

// --- Shell ---

const SidebarItem = ({ active, icon: Icon, label, onClick }: { active: boolean, icon: any, label: string, onClick: () => void }) => (
    <button
        onClick={onClick}
        className={`w-full flex flex-col items-center justify-center p-3 rounded-xl transition-all mb-2 ${active
            ? 'bg-teal-50 dark:bg-teal-900/10 text-teal-700 dark:text-teal-300 shadow-sm'
            : 'text-slate-400 hover:text-slate-600 dark:hover:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800/50'
            }`}
    >
        <Icon className={`w-6 h-6 mb-1 ${active ? 'stroke-2' : 'stroke-1.5'}`} />
        <span className="text-[10px] font-bold tracking-wide">{label}</span>
    </button>
);

const OpioidPrecisionApp = () => {
    const [activeTab, setActiveTab] = useState('decision');
    const [isDarkMode, setIsDarkMode] = useState(() => {
        if (typeof window !== 'undefined') {
            const saved = localStorage.getItem('theme');
            return saved === 'dark' || (!saved && window.matchMedia('(prefers-color-scheme: dark)').matches);
        }
        return false;
    });

    useEffect(() => {
        if (isDarkMode) {
            document.documentElement.classList.add('dark');
            localStorage.setItem('theme', 'dark');
        } else {
            document.documentElement.classList.remove('dark');
            localStorage.setItem('theme', 'light');
        }
    }, [isDarkMode]);

    return (
        <div className="flex flex-col md:flex-row h-screen bg-white dark:bg-slate-900 text-slate-900 dark:text-slate-200 font-sans overflow-hidden transition-colors duration-300">
            {/* Sidebar Navigation (Desktop) */}
            <nav className="hidden md:flex w-20 bg-white dark:bg-slate-900 border-r border-slate-200 dark:border-slate-800 flex-col items-center py-6 z-20 flex-none bg-opacity-80 backdrop-blur-md">
                <div className="mb-8">
                    <div className="w-10 h-10 bg-teal-600 rounded-xl flex items-center justify-center text-white shadow-teal-200 dark:shadow-teal-900/20 shadow-lg">
                        <Activity className="w-6 h-6" />
                    </div>
                </div>

                <div className="flex-1 w-full px-2 overflow-y-auto custom-scrollbar">
                    <SidebarItem active={activeTab === 'decision'} onClick={() => setActiveTab('decision')} icon={Home} label="Risk" />
                    <SidebarItem active={activeTab === 'sbirt'} onClick={() => setActiveTab('sbirt')} icon={ClipboardCheck} label="SBIRT" />
                    <SidebarItem active={activeTab === 'moud'} onClick={() => setActiveTab('moud')} icon={Stethoscope} label="Toolkit" />
                    <SidebarItem active={activeTab === 'proto'} onClick={() => setActiveTab('proto')} icon={BookOpen} label="Protocols" />
                    <SidebarItem active={activeTab === 'calc'} onClick={() => setActiveTab('calc')} icon={Calculator} label="Dose" />
                    <SidebarItem active={activeTab === 'ref'} onClick={() => setActiveTab('ref')} icon={Database} label="Drugs" />
                </div>

                <div className="mt-auto px-2 space-y-4 flex-none">
                    <button
                        onClick={() => setIsDarkMode(!isDarkMode)}
                        className="w-full text-slate-300 hover:text-teal-500 dark:text-slate-600 dark:hover:text-teal-400 p-2 transition-colors"
                        title="Toggle Theme"
                    >
                        {isDarkMode ? <Sun className="w-5 h-5 mx-auto" /> : <Moon className="w-5 h-5 mx-auto" />}
                    </button>
                    {/* <button className="w-full text-slate-300 hover:text-slate-500 p-2"><Settings className="w-5 h-5 mx-auto" /></button> */}
                    <div className="w-8 h-8 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-400 text-xs font-bold mx-auto border border-white dark:border-slate-700 shadow-sm">
                        DB
                    </div>
                </div>
            </nav>

            {/* Main Content Area */}
            <div className={`flex-1 flex flex-col h-full bg-slate-50/50 dark:bg-slate-900 overflow-hidden relative transition-colors duration-300`}>
                {/* Top Bar */}
                <header className="h-14 md:h-16 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between px-4 md:px-8 bg-white/80 dark:bg-slate-900/90 backdrop-blur-md z-10 flex-none">
                    <div>
                        <h1 className="text-lg md:text-xl font-bold text-slate-800 dark:text-slate-200">
                            {activeTab === 'decision' && 'Selection & Risk'}
                            {activeTab === 'sbirt' && 'SBIRT Assessment'}
                            {activeTab === 'moud' && 'Assessment Toolkit'}
                            {activeTab === 'proto' && 'Clinical Protocols'}
                            {activeTab === 'calc' && 'Conversion Calculator'}
                            {activeTab === 'ref' && 'Pharmacology Reference'}
                        </h1>
                        <p className="text-[10px] md:text-xs text-slate-400 font-medium line-clamp-1">Inpatient Opioid Management Tool</p>
                    </div>
                    <div className="md:hidden w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-slate-400 text-xs font-bold">
                        DB
                    </div>
                </header>

                <main className={`flex-1 relative ${activeTab === 'decision' ? 'overflow-hidden' : 'overflow-y-auto p-4 md:p-6'} pb-20 md:pb-0`}>
                    <div key={activeTab} className="h-full animate-fade-in">
                        {activeTab === 'decision' && <AssessmentView />}
                        {activeTab === 'sbirt' && <SBIRTView />}
                        {activeTab === 'moud' && <ToolkitView />}
                        {activeTab === 'proto' && <ProtocolsView />}
                        {activeTab === 'calc' && <CalculatorView />}
                        {activeTab === 'ref' && <ReferenceView />}
                    </div>
                </main>

                {/* Bottom Navigation (Mobile) */}
                <div className="md:hidden fixed bottom-0 left-0 right-0 bg-white dark:bg-slate-900 border-t border-slate-200 dark:border-slate-800 flex justify-around p-2 z-30 safe-area-bottom backdrop-blur-lg bg-opacity-90">
                    <button onClick={() => setActiveTab('decision')} className={`flex flex-col items-center p-2 rounded-lg ${activeTab === 'decision' ? 'text-teal-600 dark:text-teal-300 bg-teal-50 dark:bg-teal-900/10' : 'text-slate-400 dark:text-slate-500'}`}>
                        <Home className="w-5 h-5" />
                        <span className="text-[9px] font-bold mt-1">Risk</span>
                    </button>
                    <button onClick={() => setActiveTab('sbirt')} className={`flex flex-col items-center p-2 rounded-lg ${activeTab === 'sbirt' ? 'text-teal-600 dark:text-teal-300 bg-teal-50 dark:bg-teal-900/10' : 'text-slate-400 dark:text-slate-500'}`}>
                        <ClipboardCheck className="w-5 h-5" />
                        <span className="text-[9px] font-bold mt-1">SBIRT</span>
                    </button>
                    <button onClick={() => setActiveTab('moud')} className={`flex flex-col items-center p-2 rounded-lg ${activeTab === 'moud' ? 'text-teal-600 dark:text-teal-300 bg-teal-50 dark:bg-teal-900/10' : 'text-slate-400 dark:text-slate-500'}`}>
                        <Stethoscope className="w-5 h-5" />
                        <span className="text-[9px] font-bold mt-1">Tools</span>
                    </button>
                    <button onClick={() => setActiveTab('proto')} className={`flex flex-col items-center p-2 rounded-lg ${activeTab === 'proto' ? 'text-teal-600 dark:text-teal-300 bg-teal-50 dark:bg-teal-900/10' : 'text-slate-400 dark:text-slate-500'}`}>
                        <BookOpen className="w-5 h-5" />
                        <span className="text-[9px] font-bold mt-1">Proto</span>
                    </button>
                    <button onClick={() => setActiveTab('calc')} className={`flex flex-col items-center p-2 rounded-lg ${activeTab === 'calc' ? 'text-teal-600 dark:text-teal-300 bg-teal-50 dark:bg-teal-900/10' : 'text-slate-400 dark:text-slate-500'}`}>
                        <Calculator className="w-5 h-5" />
                        <span className="text-[9px] font-bold mt-1">Dose</span>
                    </button>
                    <button onClick={() => setActiveTab('ref')} className={`flex flex-col items-center p-2 rounded-lg ${activeTab === 'ref' ? 'text-teal-600 dark:text-teal-300 bg-teal-50 dark:bg-teal-900/10' : 'text-slate-400 dark:text-slate-500'}`}>
                        <Database className="w-5 h-5" />
                        <span className="text-[9px] font-bold mt-1">Drug</span>
                    </button>
                </div>
            </div>
        </div>
    );
};

export default OpioidPrecisionApp;
