"""
Krishi Bandhu (PMFBY) - Streamlined UML Use Case Diagram Generator
Refined to:
- No top header banner or badges
- No bottom footer / legend box
- Exactly 6 core use cases in Tier 1 (Farmer)
- Exactly 5 core use cases in Tier 2 (Officer/Admin, 11th point removed)
- Only clean, direct associations (no <<include>> or <<extend>>)
- 300 DPI high-definition rendering saved directly to docs/use_case_diagram.png
"""
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, Ellipse, Circle
import numpy as np

def generate_streamlined_use_case_diagram():
    # 21 x 12 inches at 300 DPI -> 6300 x 3600 pixels
    fig, ax = plt.subplots(figsize=(21, 12), dpi=300)
    ax.set_xlim(0, 21)
    ax.set_ylim(0, 12)
    ax.axis('off')

    bg_color = '#F8FAFC'      # Slate 50
    fig.patch.set_facecolor(bg_color)
    ax.set_facecolor(bg_color)

    c_slate_900 = '#0F172A'   # Deep slate
    c_slate_800 = '#1E293B'   # Dark header
    c_slate_700 = '#334155'   # Primary text
    c_slate_500 = '#64748B'   # Muted labels
    c_slate_200 = '#E2E8F0'   # Border

    # -------------------------------------------------------------
    # 1. SYSTEM BOUNDARY (x: 4.5 to 16.2, y: 0.50 to 11.50)
    # -------------------------------------------------------------
    sys_boundary = FancyBboxPatch((4.5, 0.50), 11.7, 11.00,
                                  boxstyle="round,pad=0.05,rounding_size=0.2",
                                  facecolor='#FFFFFF', edgecolor='#CBD5E1', linewidth=2.5, zorder=1)
    ax.add_patch(sys_boundary)

    # Boundary Title Tab
    sys_tab = FancyBboxPatch((4.5, 11.05), 11.7, 0.45,
                             boxstyle="round,pad=0.02,rounding_size=0.1",
                             facecolor='#F1F5F9', edgecolor='#CBD5E1', linewidth=1.5, zorder=2)
    ax.add_patch(sys_tab)
    ax.text(10.35, 11.27, "SYSTEM BOUNDARY: Krishi Bandhu Digital Crop Insurance Platform",
            fontsize=12, fontweight='bold', color=c_slate_800, ha='center', va='center', zorder=3)

    # Tier 1 & Tier 2 Containers
    # Tier 1 (Farmer: 6 Use Cases)
    tier1_bg = FancyBboxPatch((4.65, 5.95), 11.4, 4.95,
                              boxstyle="round,pad=0.03,rounding_size=0.15",
                              facecolor='#F8FAFC', edgecolor='#E2E8F0', linewidth=1.2, linestyle='--', zorder=2)
    ax.add_patch(tier1_bg)
    ax.text(4.85, 10.65, "TIER 1: FARMER USE CASES",
            fontsize=10, fontweight='bold', color='#059669', zorder=4)

    # Tier 2 (Officer/Admin: 5 Use Cases)
    tier2_bg = FancyBboxPatch((4.65, 0.65), 11.4, 5.15,
                              boxstyle="round,pad=0.03,rounding_size=0.15",
                              facecolor='#F8FAFC', edgecolor='#E2E8F0', linewidth=1.2, linestyle='--', zorder=2)
    ax.add_patch(tier2_bg)
    ax.text(4.85, 5.55, "TIER 2: OFFICER & ADMIN USE CASES",
            fontsize=10, fontweight='bold', color='#2563EB', zorder=4)

    # -------------------------------------------------------------
    # 2. HELPER FUNCTIONS
    # -------------------------------------------------------------
    use_cases = {}

    def draw_actor(x, y, name, role_badge, role_color, is_human=True, details=None):
        if is_human:
            head = Circle((x, y + 0.60), 0.24, facecolor='#FFFFFF', edgecolor=role_color, linewidth=2.5, zorder=10)
            ax.add_patch(head)
            ax.plot([x, x], [y + 0.36, y - 0.18], color=role_color, linewidth=2.5, zorder=10)
            ax.plot([x - 0.38, x + 0.38], [y + 0.18, y + 0.18], color=role_color, linewidth=2.5, zorder=10)
            ax.plot([x, x - 0.30], [y - 0.18, y - 0.65], color=role_color, linewidth=2.5, zorder=10)
            ax.plot([x, x + 0.30], [y - 0.18, y - 0.65], color=role_color, linewidth=2.5, zorder=10)
            
            tb = FancyBboxPatch((x - 1.50, y - 1.30), 3.0, 0.54,
                                boxstyle="round,pad=0.02,rounding_size=0.1",
                                facecolor='#FFFFFF', edgecolor=role_color, linewidth=1.6, zorder=10)
            ax.add_patch(tb)
            ax.text(x, y - 0.93, name, fontsize=11, fontweight='bold', color=c_slate_900,
                    ha='center', va='center', zorder=11)
            ax.text(x, y - 1.14, role_badge, fontsize=8.2, fontweight='bold', color=role_color,
                    ha='center', va='center', zorder=11)
        else:
            sb = FancyBboxPatch((x - 1.5, y - 0.58), 3.0, 1.16,
                                boxstyle="round,pad=0.03,rounding_size=0.12",
                                facecolor='#FFFFFF', edgecolor=role_color, linewidth=2, zorder=10)
            ax.add_patch(sb)
            strip = FancyBboxPatch((x - 1.5, y + 0.34), 3.0, 0.24,
                                   boxstyle="round,pad=0.02,rounding_size=0.06",
                                   facecolor=role_color, edgecolor='none', zorder=11)
            ax.add_patch(strip)
            ax.text(x, y + 0.46, "<<system>>", fontsize=7.5, fontweight='bold', color='#FFFFFF',
                    ha='center', va='center', zorder=12)
            ax.text(x, y + 0.10, name, fontsize=10, fontweight='bold', color=c_slate_900,
                    ha='center', va='center', zorder=12)
            ax.text(x, y - 0.20, role_badge, fontsize=8.0, fontweight='bold', color=role_color,
                    ha='center', va='center', zorder=12)
            if details:
                ax.text(x, y - 0.42, details, fontsize=7.2, color=c_slate_500, ha='center', va='center', zorder=12)

    def draw_use_case(key, cx, cy, rx, ry, title, lines, theme_border, theme_bg, theme_text):
        ellipse = Ellipse((cx, cy), rx * 2, ry * 2,
                          facecolor=theme_bg, edgecolor=theme_border, linewidth=1.8, zorder=5)
        ax.add_patch(ellipse)
        total_lines = [title] + lines if lines else [title]
        start_offset = (len(total_lines) - 1) * 0.13 / 2.0
        for i, line in enumerate(total_lines):
            is_title = (i == 0)
            font_size = 9.2 if is_title else 8.0
            font_weight = 'bold' if is_title else 'normal'
            tcolor = theme_text if is_title else c_slate_700
            ax.text(cx, cy + start_offset - (i * 0.16), line,
                    fontsize=font_size, fontweight=font_weight, color=tcolor,
                    ha='center', va='center', zorder=6)
        use_cases[key] = (cx, cy, rx, ry)

    # -------------------------------------------------------------
    # 3. DRAW USE CASES (6 IN TIER 1, 5 IN TIER 2)
    # Staggered positioning ensures clean open gaps for lines
    # -------------------------------------------------------------
    
    # === TIER 1: FARMER SERVICES (6 Use Cases) ===
    # Column 1 (x = 7.45)
    draw_use_case("UC1_AUTH", 7.45, 9.85, 2.30, 0.46,
                  "1. Register & Login", ["Mobile Phone OTP & KYC Profile"],
                  '#059669', '#ECFDF5', '#065F46')

    draw_use_case("UC2_LAND", 7.45, 8.40, 2.30, 0.46,
                  "2. Register Land Parcel", ["Khasra Number & GPS Boundary"],
                  '#059669', '#ECFDF5', '#065F46')

    draw_use_case("UC3_PHOTO", 7.45, 6.95, 2.30, 0.46,
                  "3. Capture Geotagged Crop Photo", ["Camera with GPS & Timestamp"],
                  '#2563EB', '#EFF6FF', '#1E40AF')

    # Column 2 (x = 13.25) - Staggered in gaps
    draw_use_case("UC4_LOSS", 13.25, 9.12, 2.30, 0.46,
                  "4. File Crop Loss Intimation", ["Report Disaster within 72 Hours"],
                  '#D97706', '#FEF3C7', '#92400E')

    draw_use_case("UC5_CLAIM", 13.25, 7.67, 2.30, 0.46,
                  "5. Submit Insurance Claim", ["Attach Land Parcel & Crop Photos"],
                  '#D97706', '#FEF3C7', '#92400E')

    draw_use_case("UC6_TRACK", 13.25, 6.22, 2.30, 0.46,
                  "6. Track Claim Status", ["View Review Progress & Payout State"],
                  '#D97706', '#FEF3C7', '#92400E')

    # === TIER 2: OFFICER & ADMIN GOVERNANCE (5 Use Cases) ===
    # Column 1 (x = 7.45)
    draw_use_case("UC7_QUEUE", 7.45, 4.70, 2.30, 0.46,
                  "7. Review Pending Claims", ["District-Scoped Claim Queue"],
                  '#7C3AED', '#F5F3FF', '#5B21B6')

    draw_use_case("UC8_VERIFY", 7.45, 3.25, 2.30, 0.46,
                  "8. Verify Crop Photo & Location", ["Validate GPS Coordinates & EXIF"],
                  '#7C3AED', '#F5F3FF', '#5B21B6')

    draw_use_case("UC9_SURVEY", 7.45, 1.80, 2.30, 0.46,
                  "9. Conduct Field Loss Survey", ["Record On-Site Loss Percentage"],
                  '#E11D48', '#FFF1F2', '#9F1239')

    # Column 2 (x = 13.25) - Staggered in gaps
    draw_use_case("UC10_ADJUDICATE", 13.25, 3.97, 2.30, 0.46,
                  "10. Adjudicate Insurance Claim", ["Approve or Reject with Payable Amount"],
                  '#E11D48', '#FFF1F2', '#9F1239')

    draw_use_case("UC11_DASHBOARD", 13.25, 2.52, 2.30, 0.46,
                  "11. View District Dashboard", ["Key Metrics, SLA & Settlement Analytics"],
                  '#0891B2', '#F0FDFA', '#115E59')

    # -------------------------------------------------------------
    # 4. DRAW ACTORS (Clear Left & Right Placement)
    # -------------------------------------------------------------
    # Primary Human Actors (Left)
    draw_actor(2.2, 8.40, "Farmer", "Primary Actor (Mobile)", '#059669', is_human=True)
    draw_actor(2.2, 3.95, "District Officer", "Primary Actor (Web)", '#2563EB', is_human=True)
    draw_actor(2.2, 1.55, "System Admin", "Superuser (Web)", '#7C3AED', is_human=True)

    # Admin inherits from Officer
    ax.annotate("", xy=(2.2, 2.70), xytext=(2.2, 2.15),
                arrowprops=dict(facecolor='#FFFFFF', edgecolor='#7C3AED', width=1.5,
                                headwidth=8, headlength=9), zorder=8)
    ax.text(2.35, 2.42, "<<inherits>>", fontsize=7.2, color='#7C3AED', fontweight='bold', rotation=90, va='center')

    # Secondary External Systems (Right)
    draw_actor(18.4, 9.85, "Firebase Auth", "Identity Provider", '#D97706', is_human=False,
               details="Phone OTP & Token Verification")

    draw_actor(18.4, 6.95, "Cloudinary Storage", "Media CDN", '#2563EB', is_human=False,
               details="Encrypted Crop Photos")

    draw_actor(18.4, 3.25, "PyTorch AI Model", "Computer Vision", '#7C3AED', is_human=False,
               details="Damage Score & Photo Screening")

    # -------------------------------------------------------------
    # 5. DRAW ASSOCIATION LINES WITH PRECISION CLEARANCE
    # NO <<include>> or <<extend>> ANYWHERE
    # -------------------------------------------------------------
    def draw_direct_assoc(ax_start, ay_start, key, color='#64748B', lw=1.5, zorder=3):
        cx, cy, rx, ry = use_cases[key]
        angle = np.arctan2(ay_start - cy, ax_start - cx)
        ex = cx + rx * np.cos(angle)
        ey = cy + ry * np.sin(angle)
        ax.plot([ax_start, ex], [ay_start, ey], color=color, linestyle='-', linewidth=lw, zorder=zorder)

    # --- Farmer Associations (Tier 1 Use Cases 1 to 6) ---
    fx, fy = 2.8, 8.40
    draw_direct_assoc(fx, fy, "UC1_AUTH", color='#059669', lw=1.5)
    draw_direct_assoc(fx, fy, "UC2_LAND", color='#059669', lw=1.5)
    draw_direct_assoc(fx, fy, "UC3_PHOTO", color='#059669', lw=1.5)
    draw_direct_assoc(fx, fy, "UC4_LOSS", color='#059669', lw=1.5)
    draw_direct_assoc(fx, fy, "UC5_CLAIM", color='#059669', lw=1.5)
    draw_direct_assoc(fx, fy, "UC6_TRACK", color='#059669', lw=1.5)

    # --- District Officer Associations (Tier 2 Use Cases 7 to 11) ---
    ox, oy = 2.8, 3.95
    draw_direct_assoc(ox, oy, "UC7_QUEUE", color='#2563EB', lw=1.5)
    draw_direct_assoc(ox, oy, "UC8_VERIFY", color='#2563EB', lw=1.5)
    draw_direct_assoc(ox, oy, "UC9_SURVEY", color='#2563EB', lw=1.5)
    draw_direct_assoc(ox, oy, "UC10_ADJUDICATE", color='#2563EB', lw=1.5)
    draw_direct_assoc(ox, oy, "UC11_DASHBOARD", color='#2563EB', lw=1.5)

    # --- System Admin Associations ---
    admin_x, admin_y = 2.8, 1.55
    draw_direct_assoc(admin_x, admin_y, "UC11_DASHBOARD", color='#7C3AED', lw=1.5)

    # --- External System Associations (Right Side) ---
    draw_direct_assoc(16.9, 9.85, "UC1_AUTH", color='#D97706', lw=1.5)
    draw_direct_assoc(16.9, 6.95, "UC3_PHOTO", color='#2563EB', lw=1.5)
    draw_direct_assoc(16.9, 3.25, "UC8_VERIFY", color='#7C3AED', lw=1.5)

    # Output diagram at 300 DPI high-definition resolution
    output_path = 'docs/use_case_diagram.png'
    plt.tight_layout()
    plt.savefig(output_path, dpi=300, facecolor=fig.get_facecolor(), edgecolor='none', bbox_inches='tight')
    plt.close()
    print(f"Minimalist Use Case Diagram successfully generated at: {output_path}")

if __name__ == '__main__':
    generate_streamlined_use_case_diagram()
