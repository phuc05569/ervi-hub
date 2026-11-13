using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
public static class ErviNativeInput {
 [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X,Y; }
 [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left,Top,Right,Bottom; }
 [StructLayout(LayoutKind.Sequential)] public struct MOUSEINPUT { public int dx,dy; public uint mouseData,flags,time; public UIntPtr extra; }
 [StructLayout(LayoutKind.Sequential)] public struct KEYBDINPUT { public ushort vk,scan;public uint flags,time;public UIntPtr extra; }
 [StructLayout(LayoutKind.Explicit)] public struct INPUTUNION { [FieldOffset(0)] public MOUSEINPUT mouse;[FieldOffset(0)] public KEYBDINPUT key; }
 [StructLayout(LayoutKind.Sequential)] public struct INPUT { public uint type;public INPUTUNION data; }
 [DllImport("user32.dll",SetLastError=true)] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h,out RECT r);
 [DllImport("user32.dll")] public static extern bool GetCursorPos(out POINT p);
 [DllImport("user32.dll",SetLastError=true)] public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr window,ref POINT p);
 [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint code,uint kind);
 [DllImport("user32.dll",SetLastError=true)] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr context);
 [DllImport("user32.dll")] public static extern int GetSystemMetrics(int index);
 [DllImport("user32.dll",SetLastError=true)] public static extern uint SendInput(uint count,INPUT[] input,int size);
 static void Guard(IntPtr target) { if(target==IntPtr.Zero||GetForegroundWindow()!=target) throw new InvalidOperationException("Target window is not foreground; no input sent"); }
 public static uint Move(IntPtr target,int dx,int dy) { Guard(target);var input=new INPUT {type=0,data=new INPUTUNION{mouse=new MOUSEINPUT{dx=dx,dy=dy,flags=1}}};return SendInput(1,new[]{input},Marshal.SizeOf(typeof(INPUT))); }
 public static uint Key(IntPtr target,ushort vk,bool up) { Guard(target);var input=new INPUT{type=1,data=new INPUTUNION{key=new KEYBDINPUT{vk=vk,flags=up?2u:0u}}};return SendInput(1,new[]{input},Marshal.SizeOf(typeof(INPUT))); }
 static uint Extended(ushort vk) { return ((vk>=0x21 && vk<=0x28)||vk==0x2D||vk==0x2E||vk==0xA3||vk==0xA5||vk==0x6F||vk==0x5B||vk==0x5C)?1u:0u; }
 public static uint ScanKey(IntPtr target,ushort vk,bool up) { Guard(target);var scan=MapVirtualKey(vk,0);if(scan==0) throw new InvalidOperationException("No scan code mapping");var input=new INPUT{type=1,data=new INPUTUNION{key=new KEYBDINPUT{scan=(ushort)scan,flags=8u|Extended(vk)|(up?2u:0u)}}};return SendInput(1,new[]{input},Marshal.SizeOf(typeof(INPUT))); }
 public static bool PointAt(IntPtr target,int x,int y) { Guard(target);RECT r;if(!GetWindowRect(target,out r)||x<r.Left||x>=r.Right||y<r.Top||y>=r.Bottom) throw new InvalidOperationException("Click target lies outside the verified window");int w=GetSystemMetrics(78),h=GetSystemMetrics(79);if(w<2||h<2)throw new InvalidOperationException("Invalid virtual display bounds");var input=new INPUT{type=0,data=new INPUTUNION{mouse=new MOUSEINPUT{dx=(int)Math.Round((x-GetSystemMetrics(76))*65535.0/(w-1)),dy=(int)Math.Round((y-GetSystemMetrics(77))*65535.0/(h-1)),flags=0xC001}}};return SendInput(1,new[]{input},Marshal.SizeOf(typeof(INPUT)))==1; }
 public static uint Click(IntPtr target) { Guard(target);POINT p;RECT r;if(!GetCursorPos(out p)||!GetWindowRect(target,out r)||p.X<r.Left||p.X>=r.Right||p.Y<r.Top||p.Y>=r.Bottom) throw new InvalidOperationException("Cursor lies outside the verified window");var down=new INPUT{type=0,data=new INPUTUNION{mouse=new MOUSEINPUT{flags=2}}};var up=new INPUT{type=0,data=new INPUTUNION{mouse=new MOUSEINPUT{flags=4}}};return SendInput(2,new[]{down,up},Marshal.SizeOf(typeof(INPUT))); }
 public static uint Button(IntPtr target,bool up) { Guard(target);var input=new INPUT{type=0,data=new INPUTUNION{mouse=new MOUSEINPUT{flags=up?4u:2u}}};return SendInput(1,new[]{input},Marshal.SizeOf(typeof(INPUT))); }
 public static uint ReleaseKey(ushort vk) { var input=new INPUT{type=1,data=new INPUTUNION{key=new KEYBDINPUT{scan=(ushort)MapVirtualKey(vk,0),flags=10u|Extended(vk)}}};return SendInput(1,new[]{input},Marshal.SizeOf(typeof(INPUT))); }
 public static uint ReleaseMouse() {var input=new INPUT{type=0,data=new INPUTUNION{mouse=new MOUSEINPUT{flags=4}}};return SendInput(1,new[]{input},Marshal.SizeOf(typeof(INPUT)));}
 public static uint Wheel(IntPtr target,int delta) { Guard(target);var input=new INPUT{type=0,data=new INPUTUNION{mouse=new MOUSEINPUT{mouseData=unchecked((uint)delta),flags=0x800}}};return SendInput(1,new[]{input},Marshal.SizeOf(typeof(INPUT))); }
 public static uint Text(IntPtr target,string text) { Guard(target);var inputs=new INPUT[text.Length*2];for(int i=0;i<text.Length;i++){inputs[2*i]=new INPUT{type=1,data=new INPUTUNION{key=new KEYBDINPUT{scan=text[i],flags=4}}};inputs[2*i+1]=new INPUT{type=1,data=new INPUTUNION{key=new KEYBDINPUT{scan=text[i],flags=6}}};}return SendInput((uint)inputs.Length,inputs,Marshal.SizeOf(typeof(INPUT))); }
 public static uint PressAt(IntPtr target,int x,int y) { Guard(target);RECT r;if(!GetWindowRect(target,out r)||x<r.Left||x>=r.Right||y<r.Top||y>=r.Bottom)throw new InvalidOperationException("Target outside window");int w=GetSystemMetrics(78),h=GetSystemMetrics(79);var input=new INPUT{type=0,data=new INPUTUNION{mouse=new MOUSEINPUT{dx=(int)Math.Round((x-GetSystemMetrics(76))*65535.0/(w-1)),dy=(int)Math.Round((y-GetSystemMetrics(77))*65535.0/(h-1)),flags=0xC003}}};return SendInput(1,new[]{input},Marshal.SizeOf(typeof(INPUT))); }
}
