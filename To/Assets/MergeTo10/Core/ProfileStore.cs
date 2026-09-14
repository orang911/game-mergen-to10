using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using UnityEngine;
namespace MergeTo10.Core
{
 // One envelope stores profile and run/checkpoint together. Never write to the
 // original Godot user:// profile, and never treat a corrupt save as a new game.
 public sealed class ProfileStore {
  [Serializable] public sealed class Envelope {public int Version=1;public string Payload,Checksum;}
  readonly string path;
  bool rejectedPrimary;
  public string FilePath=>path;
  public ProfileStore(string absolutePath){if(!Path.IsPathRooted(absolutePath))throw new ArgumentException("Absolute save path required");path=absolutePath;}
  static string Hash(string data){using(var hash=SHA256.Create())return BitConverter.ToString(hash.ComputeHash(Encoding.UTF8.GetBytes(data))).Replace("-","");}
  public void Save(string payload){
   if(string.IsNullOrEmpty(payload))throw new ArgumentException("Empty profile payload");
   string directory=Path.GetDirectoryName(path);Directory.CreateDirectory(directory);
   string temp=path+".pending";
   byte[] bytes=Encoding.UTF8.GetBytes(JsonUtility.ToJson(new Envelope{Payload=payload,Checksum=Hash(payload)}));
   using(var file=new FileStream(temp,FileMode.Create,FileAccess.Write,FileShare.None)){file.Write(bytes,0,bytes.Length);file.Flush(true);}
   if(File.Exists(path)){
    bool valid=!rejectedPrimary&&TryRead(path,out _);
    if(!valid)File.Copy(path,path+".corrupt_"+Guid.NewGuid().ToString("N"));
    File.Replace(temp,path,valid?path+".backup":null);
   }else File.Move(temp,path);
   rejectedPrimary=false;
  }
  public string Load(out bool recoveredBackup,Action<string> validate=null){
   recoveredBackup=false;rejectedPrimary=false;
   foreach(string candidate in new[]{path,path+".backup",path+".pending"}){
    if(!TryRead(candidate,out var payload))continue;
    try{validate?.Invoke(payload);}catch(ArgumentException){if(candidate==path)rejectedPrimary=true;continue;}catch(InvalidDataException){if(candidate==path)rejectedPrimary=true;continue;}
    recoveredBackup=candidate!=path;return payload;
   }
   if(File.Exists(path)||File.Exists(path+".backup")||File.Exists(path+".pending"))throw new InvalidDataException("Profile is incomplete or corrupt; original files were preserved.");
   return null;
  }
  // Only invoked by the in-game second confirmation. Archive before replacing any file.
  public string Reset(string payload){
   string archive=path+".reset_"+Guid.NewGuid().ToString("N");
   Directory.CreateDirectory(archive);
   string[] files={path,path+".backup",path+".pending"};
   foreach(string file in files)if(File.Exists(file))File.Copy(file,Path.Combine(archive,Path.GetFileName(file)));
   try{
    foreach(string file in files)if(File.Exists(file))File.Delete(file);
    Save(payload);
   }catch{
    foreach(string file in files){string old=Path.Combine(archive,Path.GetFileName(file));if(File.Exists(old))File.Copy(old,file,true);else if(File.Exists(file))File.Delete(file);}
    throw;
   }
   return archive;
  }
  static bool TryRead(string source,out string payload){
   payload=null;if(!File.Exists(source))return false;
   try{var envelope=JsonUtility.FromJson<Envelope>(File.ReadAllText(source,Encoding.UTF8));
    if(envelope==null||envelope.Version!=1||string.IsNullOrEmpty(envelope.Payload)||envelope.Checksum!=Hash(envelope.Payload))return false;
    payload=envelope.Payload;return true;
   }catch(ArgumentException){return false;}
  }
 }
}
