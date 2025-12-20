import React, { useState } from 'react';
import {
    Activity,
    ChevronDown,
    ChevronUp,
    Search,
    Zap
} from 'lucide-react';
import { Badge } from './Shared';
import { DRUG_DATA } from './data';

export const ReferenceView = () => {
    const [searchTerm, setSearchTerm] = useState('');
    const [expanded, setExpanded] = useState<string | null>(null);

    const filtered = DRUG_DATA.filter(d =>
        d.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        d.clinical_nuance.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div className="max-w-4xl mx-auto space-y-6">
            <div className="relative">
                <Search className="absolute left-3 top-3.5 h-4 w-4 text-slate-400" />
                <input
                    type="text"
                    placeholder="Search by drug, metabolite, or mechanism..."
                    className="w-full pl-9 pr-4 py-3 rounded-xl border border-slate-200 outline-none focus:ring-2 focus:ring-teal-100 focus:border-teal-500 text-sm shadow-sm"
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                />
            </div>

            <div className="space-y-3">
                {filtered.map(drug => (
                    <div key={drug.id} className="bg-white rounded-lg border border-slate-200 overflow-hidden shadow-sm hover:shadow-md transition-all">
                        <div
                            onClick={() => setExpanded(expanded === drug.id ? null : drug.id)}
                            className="p-4 cursor-pointer flex justify-between items-center group"
                        >
                            <div>
                                <div className="flex items-center gap-3">
                                    <h3 className="font-bold text-slate-800">{drug.name}</h3>
                                    <Badge type={drug.type} text={drug.renal_safety === 'Safe' ? 'Renal Safe' : 'Renal Caution'} />
                                </div>
                                <div className="text-xs text-slate-500 mt-1">{drug.type}</div>
                            </div>
                            <div className={`p-1 rounded-full transition-colors ${expanded === drug.id ? 'bg-slate-100 text-slate-600' : 'text-slate-300 group-hover:text-slate-500'}`}>
                                {expanded === drug.id ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
                            </div>
                        </div>

                        {expanded === drug.id && (
                            <div className="bg-slate-50 px-4 pb-4 pt-4 border-t border-slate-100 text-sm">
                                <div className="grid md:grid-cols-2 gap-4 mb-4">
                                    <div className="bg-white p-3 rounded border border-slate-200">
                                        <span className="block text-[10px] font-bold text-slate-400 uppercase tracking-wide mb-1">IV Profile</span>
                                        <span className="text-slate-700 font-medium">{drug.iv_onset} onset / {drug.iv_duration} duration</span>
                                    </div>
                                    <div className="bg-white p-3 rounded border border-slate-200">
                                        <span className="block text-[10px] font-bold text-slate-400 uppercase tracking-wide mb-1">Bioavailability</span>
                                        <div className="flex items-center gap-2">
                                            <div className="flex-1 h-1.5 bg-slate-100 rounded-full overflow-hidden">
                                                <div className="h-full bg-teal-500" style={{ width: `${drug.bioavailability}%` }}></div>
                                            </div>
                                            <span className="text-xs font-bold text-slate-600 w-8">{drug.bioavailability > 0 ? `${drug.bioavailability}%` : 'N/A'}</span>
                                        </div>
                                    </div>
                                </div>

                                <div className="space-y-3">
                                    <div className="flex gap-3">
                                        <Zap className="w-4 h-4 text-purple-500 flex-none mt-0.5" />
                                        <div>
                                            <h4 className="text-xs font-bold text-slate-900 uppercase mb-1">Clinical Nuance</h4>
                                            <p className="text-slate-600 leading-relaxed">{drug.clinical_nuance}</p>
                                        </div>
                                    </div>
                                    <div className="flex gap-3">
                                        <Activity className="w-4 h-4 text-slate-400 flex-none mt-0.5" />
                                        <div>
                                            <h4 className="text-xs font-bold text-slate-900 uppercase mb-1">Pharmacokinetics</h4>
                                            <p className="text-slate-500 leading-relaxed text-xs">{drug.pharmacokinetics}</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        )}
                    </div>
                ))}
            </div>
        </div>
    );
};
