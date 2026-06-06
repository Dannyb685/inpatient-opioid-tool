import re
import os

integration_path = 'integration.html'
index_path = 'index.html'

with open(integration_path, 'r') as f:
    integration_content = f.read()

# Extract from integration.html
# Architecture section
arch_match = re.search(r'<!-- How It Works / Architecture -->.*?</section>', integration_content, re.DOTALL)
timeline_match = re.search(r'<!-- Implementation Timeline -->.*?</section>', integration_content, re.DOTALL)

if not arch_match or not timeline_match:
    print("Failed to extract sections")
    exit(1)

extracted_html = "\n" + arch_match.group(0) + "\n\n" + timeline_match.group(0) + "\n"

with open(index_path, 'r') as f:
    index_content = f.read()

# Insert into index.html before <section id="benchmarks"
index_content = index_content.replace('<section id="benchmarks"', extracted_html + '\n    <section id="benchmarks"')

# Replace nav desktop
old_nav_desktop = """            <div class="hidden md:flex gap-6 text-sm font-medium text-slate-600">
                <a href="#impact" class="hover:text-clinical-teal transition">The Problem</a>
                <a href="#ios-app" class="hover:text-clinical-teal transition">The iOS App</a>
                <a href="integration.html" class="hover:text-clinical-teal transition">EMR Integration</a>
                <a href="appstore.html" class="hover:text-clinical-teal transition">Clinical Showcase</a>
            </div>"""
new_nav_desktop = """            <div class="hidden md:flex gap-6 text-sm font-medium text-slate-600">
                <a href="#impact" class="hover:text-clinical-teal transition">The Problem</a>
                <a href="#ios-app" class="hover:text-clinical-teal transition">The iOS App</a>
                <a href="#architecture" class="hover:text-clinical-teal transition">EMR Integration</a>
                <a href="#benchmarks" class="hover:text-clinical-teal transition">Benchmarks</a>
            </div>"""
index_content = index_content.replace(old_nav_desktop, new_nav_desktop)

# Replace nav mobile
old_nav_mobile = """            <div class="flex flex-col gap-3 text-sm font-medium text-slate-600">
                <a href="#impact" class="hover:text-clinical-teal transition py-2" onclick="document.getElementById('mobile-menu').classList.add('hidden')">The Problem</a>
                <a href="#ios-app" class="hover:text-clinical-teal transition py-2" onclick="document.getElementById('mobile-menu').classList.add('hidden')">The iOS App</a>
                <a href="integration.html" class="hover:text-clinical-teal transition py-2" onclick="document.getElementById('mobile-menu').classList.add('hidden')">EMR Integration</a>
                <a href="appstore.html" class="hover:text-clinical-teal transition py-2" onclick="document.getElementById('mobile-menu').classList.add('hidden')">Clinical Showcase</a>"""
new_nav_mobile = """            <div class="flex flex-col gap-3 text-sm font-medium text-slate-600">
                <a href="#impact" class="hover:text-clinical-teal transition py-2" onclick="document.getElementById('mobile-menu').classList.add('hidden')">The Problem</a>
                <a href="#ios-app" class="hover:text-clinical-teal transition py-2" onclick="document.getElementById('mobile-menu').classList.add('hidden')">The iOS App</a>
                <a href="#architecture" class="hover:text-clinical-teal transition py-2" onclick="document.getElementById('mobile-menu').classList.add('hidden')">EMR Integration</a>
                <a href="#benchmarks" class="hover:text-clinical-teal transition py-2" onclick="document.getElementById('mobile-menu').classList.add('hidden')">Benchmarks</a>"""
index_content = index_content.replace(old_nav_mobile, new_nav_mobile)

# Fix hero CTA links
old_hero_cta = """                <div class="flex gap-4 flex-col sm:flex-row justify-center md:justify-start">
                    <a href="https://testflight.apple.com/join/wnNw14QZ" target="_blank" class="bg-clinical-teal text-white px-8 py-4 rounded-xl font-semibold hover:bg-teal-700 transition shadow-lg shadow-teal-500/20 flex items-center justify-center gap-2">
                        <i data-lucide="smartphone" class="w-5 h-5"></i> Join iOS Beta
                    </a>
                    <a href="integration.html" class="bg-white text-slate-700 border border-slate-200 px-8 py-4 rounded-xl font-semibold hover:bg-slate-50 transition flex items-center justify-center gap-2">
                        <i data-lucide="server" class="w-5 h-5"></i> EMR Integration Guide
                    </a>
                </div>"""
new_hero_cta = """                <div class="flex gap-4 flex-col sm:flex-row justify-center md:justify-start">
                    <a href="https://testflight.apple.com/join/wnNw14QZ" target="_blank" class="bg-clinical-teal text-white px-8 py-4 rounded-xl font-semibold hover:bg-teal-700 transition shadow-lg shadow-teal-500/20 flex items-center justify-center gap-2">
                        <i data-lucide="smartphone" class="w-5 h-5"></i> Join iOS Beta
                    </a>
                    <a href="#architecture" class="bg-white text-slate-700 border border-slate-200 px-8 py-4 rounded-xl font-semibold hover:bg-slate-50 transition flex items-center justify-center gap-2">
                        <i data-lucide="server" class="w-5 h-5"></i> EMR Integration Guide
                    </a>
                </div>"""
index_content = index_content.replace(old_hero_cta, new_hero_cta)

# Fix iOS app section CTA
old_ios_cta = """                        <a href="appstore.html" class="bg-white text-slate-700 border border-slate-200 px-6 py-3 rounded-xl font-semibold hover:bg-slate-50 transition flex items-center justify-center gap-2 text-sm">
                            <i data-lucide="image" class="w-4 h-4"></i> View Full Feature Showcase →
                        </a>"""
new_ios_cta = """                        <a href="#architecture" class="bg-white text-slate-700 border border-slate-200 px-6 py-3 rounded-xl font-semibold hover:bg-slate-50 transition flex items-center justify-center gap-2 text-sm">
                            <i data-lucide="server" class="w-4 h-4"></i> View EMR Integration →
                        </a>"""
index_content = index_content.replace(old_ios_cta, new_ios_cta)

# Fix footer
old_footer = """                <div class="flex gap-4 text-sm text-slate-400">
                    <a href="appstore" class="hover:text-white transition">Clinical Showcase</a>
                    <a href="integration.html" class="hover:text-white transition">EMR Integration</a>
                    <a href="privacy" class="hover:text-white transition">Privacy Policy</a>
                    <a href="support" class="hover:text-white transition">Support</a>
                    <a href="https://www.instagram.com/lifelinemedtech/" target="_blank" class="hover:text-white transition">Instagram</a>
                </div>"""
new_footer = """                <div class="flex gap-4 text-sm text-slate-400">
                    <a href="privacy" class="hover:text-white transition">Privacy Policy</a>
                    <a href="support" class="hover:text-white transition">Support</a>
                    <a href="https://www.instagram.com/lifelinemedtech/" target="_blank" class="hover:text-white transition">Instagram</a>
                </div>"""
index_content = index_content.replace(old_footer, new_footer)

with open(index_path, 'w') as f:
    f.write(index_content)

print("Done")
