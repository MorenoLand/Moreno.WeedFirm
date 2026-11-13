param(
	[Parameter(Mandatory = $true)][string]$Exe,
	[Parameter(Mandatory = $true)][string]$Png
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
public static class WfIcon {
	delegate bool NameProc(IntPtr m, IntPtr type, IntPtr name, IntPtr p);
	delegate bool LangProc(IntPtr m, IntPtr type, IntPtr name, ushort lang, IntPtr p);
	[DllImport("kernel32", SetLastError = true, CharSet = CharSet.Unicode)] static extern IntPtr LoadLibraryEx(string f, IntPtr h, uint fl);
	[DllImport("kernel32", SetLastError = true)] static extern bool FreeLibrary(IntPtr m);
	[DllImport("kernel32", SetLastError = true)] static extern bool EnumResourceNames(IntPtr m, IntPtr type, NameProc p, IntPtr l);
	[DllImport("kernel32", SetLastError = true)] static extern bool EnumResourceLanguages(IntPtr m, IntPtr type, IntPtr name, LangProc p, IntPtr l);
	[DllImport("kernel32", SetLastError = true, CharSet = CharSet.Unicode)] static extern IntPtr BeginUpdateResource(string f, bool del);
	[DllImport("kernel32", SetLastError = true)] static extern bool UpdateResource(IntPtr h, IntPtr type, IntPtr name, ushort lang, byte[] data, uint cb);
	[DllImport("kernel32", SetLastError = true)] static extern bool EndUpdateResource(IntPtr h, bool discard);
	static IntPtr Name(object n) { return n is string ? Marshal.StringToHGlobalUni((string)n) : (IntPtr)(long)n; }
	static List<KeyValuePair<object, ushort>> Find(IntPtr m, int type) {
		var res = new List<KeyValuePair<object, ushort>>();
		EnumResourceNames(m, (IntPtr)type, (mm, t, n, p) => {
			object id = n.ToInt64() > 0xFFFF ? (object)Marshal.PtrToStringUni(n) : (object)n.ToInt64();
			EnumResourceLanguages(mm, t, n, (m2, t2, n2, lang, p2) => { res.Add(new KeyValuePair<object, ushort>(id, lang)); return true; }, IntPtr.Zero);
			return true;
		}, IntPtr.Zero);
		return res;
	}
	public static void Apply(string exe, byte[][] pngs, int[] sizes) {
		IntPtr m = LoadLibraryEx(exe, IntPtr.Zero, 0x2);
		if (m == IntPtr.Zero) throw new Exception("cannot open " + exe);
		var groups = Find(m, 14);
		var icons = Find(m, 3);
		FreeLibrary(m);
		ushort lang = groups.Count > 0 ? groups[0].Value : (ushort)1033;
		object gid = groups.Count > 0 ? groups[0].Key : (object)1L;
		IntPtr h = BeginUpdateResource(exe, false);
		if (h == IntPtr.Zero) throw new Exception("BeginUpdateResource failed");
		foreach (var i in icons) UpdateResource(h, (IntPtr)3, Name(i.Key), i.Value, null, 0);
		for (int k = 1; k < groups.Count; k++) UpdateResource(h, (IntPtr)14, Name(groups[k].Key), groups[k].Value, null, 0);
		var ms = new MemoryStream();
		var w = new BinaryWriter(ms);
		w.Write((ushort)0); w.Write((ushort)1); w.Write((ushort)pngs.Length);
		for (int i = 0; i < pngs.Length; i++) {
			int id = 100 + i;
			if (!UpdateResource(h, (IntPtr)3, (IntPtr)id, lang, pngs[i], (uint)pngs[i].Length)) throw new Exception("UpdateResource icon failed");
			byte dim = (byte)(sizes[i] >= 256 ? 0 : sizes[i]);
			w.Write(dim); w.Write(dim);
			w.Write((byte)0); w.Write((byte)0); w.Write((ushort)1); w.Write((ushort)32);
			w.Write((uint)pngs[i].Length); w.Write((ushort)id);
		}
		byte[] grp = ms.ToArray();
		if (!UpdateResource(h, (IntPtr)14, Name(gid), lang, grp, (uint)grp.Length)) throw new Exception("UpdateResource group failed");
		if (!EndUpdateResource(h, false)) throw new Exception("EndUpdateResource failed");
	}
}
'@
$src = [System.Drawing.Image]::FromFile((Resolve-Path $Png).Path)
$sizes = @(16, 24, 32, 48, 64, 128, 256)
$pngs = New-Object 'System.Collections.Generic.List[byte[]]'
foreach ($s in $sizes) {
	$bmp = New-Object System.Drawing.Bitmap $s, $s, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$g = [System.Drawing.Graphics]::FromImage($bmp)
	$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
	$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
	$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
	$g.DrawImage($src, 0, 0, $s, $s)
	$g.Dispose()
	$ms = New-Object System.IO.MemoryStream
	$bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
	$pngs.Add($ms.ToArray())
	$bmp.Dispose(); $ms.Dispose()
}
$src.Dispose()
[WfIcon]::Apply((Resolve-Path $Exe).Path, $pngs.ToArray(), [int[]]$sizes)
