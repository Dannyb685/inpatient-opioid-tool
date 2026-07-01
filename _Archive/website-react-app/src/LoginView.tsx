import React, { useState } from 'react';
import { supabase } from './lib/supabase';
import { ShieldAlert, Lock, Mail, Key } from 'lucide-react';

export const LoginView = () => {
    const [loading, setLoading] = useState(false);
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [licenseKey, setLicenseKey] = useState(''); // Placeholder for licensing
    const [error, setError] = useState<string | null>(null);

    const handleLogin = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError(null);

        try {
            const { error } = await supabase.auth.signInWithPassword({
                email,
                password,
            });
            if (error) throw error;
        } catch (err: any) {
            setError(err.message || 'Failed to login');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen flex items-center justify-center bg-surface-base p-4">
            <div className="w-full max-w-md space-y-8">
                <div className="text-center">
                    <div className="bg-action rounded-2xl w-16 h-16 flex items-center justify-center mx-auto mb-4 shadow-lg shadow-action/30">
                        <ShieldAlert className="w-8 h-8 text-white" />
                    </div>
                    <h2 className="text-3xl font-bold text-text-primary tracking-tight">Opioid Precision</h2>
                    <p className="mt-2 text-text-secondary">Clinical SaaS Portal</p>
                </div>

                <div className="bg-surface-card p-8 rounded-2xl border border-border shadow-xl">
                    <form onSubmit={handleLogin} className="space-y-6">
                        {/* Email */}
                        <div>
                            <label className="block text-xs font-bold text-text-tertiary uppercase mb-1">Email Address</label>
                            <div className="relative">
                                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                    <Mail className="h-5 w-5 text-text-tertiary" />
                                </div>
                                <input
                                    type="email"
                                    required
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    className="block w-full pl-10 pr-3 py-2 border border-border rounded-xl bg-surface-highlight text-text-primary placeholder-text-tertiary focus:outline-none focus:ring-2 focus:ring-action focus:border-transparent transition-all"
                                    placeholder="doctor@hospital.org"
                                />
                            </div>
                        </div>

                        {/* Password */}
                        <div>
                            <label className="block text-xs font-bold text-text-tertiary uppercase mb-1">Password</label>
                            <div className="relative">
                                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                    <Lock className="h-5 w-5 text-text-tertiary" />
                                </div>
                                <input
                                    type="password"
                                    required
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    className="block w-full pl-10 pr-3 py-2 border border-border rounded-xl bg-surface-highlight text-text-primary placeholder-text-tertiary focus:outline-none focus:ring-2 focus:ring-action focus:border-transparent transition-all"
                                    placeholder="••••••••"
                                />
                            </div>
                        </div>

                        {/* License Key (Placeholder) */}
                        <div>
                            <label className="block text-xs font-bold text-text-tertiary uppercase mb-1 flex justify-between">
                                <span>Enterprise License Key</span>
                                <span className="text-[10px] text-action">Optional</span>
                            </label>
                            <div className="relative">
                                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                    <Key className="h-5 w-5 text-text-tertiary" />
                                </div>
                                <input
                                    type="text"
                                    value={licenseKey}
                                    onChange={(e) => setLicenseKey(e.target.value)}
                                    className="block w-full pl-10 pr-3 py-2 border border-border rounded-xl bg-surface-highlight text-text-primary placeholder-text-tertiary focus:outline-none focus:ring-2 focus:ring-action focus:border-transparent transition-all"
                                    placeholder="XXXX-XXXX-XXXX-XXXX"
                                />
                            </div>
                        </div>

                        {error && (
                            <div className="bg-danger-bg text-danger text-sm p-3 rounded-lg flex items-center gap-2">
                                <ShieldAlert className="w-4 h-4 flex-none" />
                                {error}
                            </div>
                        )}

                        <button
                            type="submit"
                            disabled={loading}
                            className={`w-full flex justify-center py-3 px-4 border border-transparent rounded-xl shadow-sm text-sm font-bold text-white bg-action hover:bg-action/90 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-action transition-all transform active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed`}
                        >
                            {loading ? 'Authenticating...' : 'Sign In'}
                        </button>
                    </form>

                    <div className="mt-6">
                        <div className="relative">
                            <div className="absolute inset-0 flex items-center">
                                <div className="w-full border-t border-border" />
                            </div>
                            <div className="relative flex justify-center text-sm">
                                <span className="px-2 bg-surface-card text-text-tertiary">
                                    Or
                                </span>
                            </div>
                        </div>

                        <div className="mt-6 grid grid-cols-1 gap-3">
                            <button
                                type="button"
                                className="w-full inline-flex justify-center py-2.5 px-4 border border-border rounded-xl shadow-sm bg-surface-base text-sm font-medium text-text-secondary hover:bg-surface-highlight transition-colors"
                            >
                                <span className="sr-only">Sign in with Epic</span>
                                <span>Continue with Epic Systems SSO</span>
                            </button>
                        </div>
                    </div>
                </div>

                <p className="text-center text-xs text-text-tertiary">
                    © 2026 Clinical Systems. HIPAA Compliant.
                </p>
            </div>
        </div>
    );
};
