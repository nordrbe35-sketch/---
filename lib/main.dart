import os, textwrap, zipfile

base = "/mnt/data/ClinicNajwaAndroid"
files = {
"settings.gradle": """pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement { repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS); repositories { google(); mavenCentral() } }
rootProject.name = "ClinicNajwa"
include ':app'
""",
"build.gradle": """plugins {
    id 'com.android.application' version '7.4.2' apply false
}
""",
"gradle.properties": """org.gradle.jvmargs=-Xmx1536m
android.useAndroidX=true
""",
"app/build.gradle": """plugins {
    id 'com.android.application'
}
android {
    namespace 'com.najwa.clinic'
    compileSdk 33
    defaultConfig {
        applicationId 'com.najwa.clinic'
        minSdk 23
        targetSdk 32
        versionCode 1
        versionName '1.0'
    }
}
""",
"app/src/main/AndroidManifest.xml": """<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:allowBackup="false"
        android:label="عيادة دكتورة نجوي"
        android:theme="@android:style/Theme.Material.Light.NoActionBar"
        android:supportsRtl="true">
        <activity
            android:name=".MainActivity"
            android:screenOrientation="portrait"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
""",
"app/src/main/java/com/najwa/clinic/MainActivity.java": r'''package com.najwa.clinic;

import android.app.*;
import android.os.Bundle;
import android.content.*;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.graphics.Color;
import android.graphics.Typeface;
import android.view.*;
import android.view.inputmethod.InputMethodManager;
import android.widget.*;
import java.text.SimpleDateFormat;
import java.util.*;

public class MainActivity extends Activity {
    int purple = Color.rgb(79, 70, 190), ink = Color.rgb(38, 43, 79);
    int bg = Color.rgb(246, 247, 252), green = Color.rgb(18, 153, 117), red = Color.rgb(207, 66, 90);
    LinearLayout root, body, nav;
    DB db;
    String page = "home";
    EditText searchBox;
    final String[] pages = {"الرئيسية","حجز موعد","المواعيد","المرضى","التقارير"};
    @Override public void onCreate(Bundle b) {
        super.onCreate(b);
        getWindow().setStatusBarColor(purple);
        getWindow().setNavigationBarColor(ink);
        db = new DB(this);
        showPage("الرئيسية");
    }
    int dp(int n){ return (int)(n*getResources().getDisplayMetrics().density+.5f); }
    TextView text(String s,int size,int color,boolean bold){
        TextView t=new TextView(this); t.setText(s); t.setTextSize(size); t.setTextColor(color);
        t.setGravity(Gravity.RIGHT|Gravity.CENTER_VERTICAL); t.setTypeface(Typeface.DEFAULT,bold?Typeface.BOLD:Typeface.NORMAL);
        t.setPadding(dp(3),dp(5),dp(3),dp(5)); return t;
    }
    LinearLayout column(){ LinearLayout l=new LinearLayout(this); l.setOrientation(LinearLayout.VERTICAL); return l; }
    LinearLayout row(){ LinearLayout l=new LinearLayout(this); l.setOrientation(LinearLayout.HORIZONTAL); l.setGravity(Gravity.CENTER_VERTICAL); return l; }
    GradientDrawable shape(int color,int radius){
        GradientDrawable d=new GradientDrawable(); d.setColor(color); d.setCornerRadius(dp(radius)); return d;
    }
    void pad(View v,int n){ v.setPadding(dp(n),dp(n),dp(n),dp(n)); }
    TextView button(String label, int color, Runnable action){
        TextView b=text(label,14,Color.WHITE,true); b.setGravity(Gravity.CENTER); b.setPadding(dp(12),dp(12),dp(12),dp(12));
        b.setBackground(shape(color,12)); b.setOnClickListener(v->action.run());
        LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,-2); p.setMargins(0,dp(5),0,dp(5)); b.setLayoutParams(p); return b;
    }
    TextView smallButton(String label,int color,Runnable action){
        TextView b=text(label,12,color,true); b.setGravity(Gravity.CENTER); b.setPadding(dp(8),dp(8),dp(8),dp(8));
        b.setBackground(shape(Color.rgb(239,239,251),9)); b.setOnClickListener(v->action.run());
        return b;
    }
    void showPage(String p){
        page=p; root=column(); root.setBackgroundColor(bg); setContentView(root);
        LinearLayout header=column(); header.setBackground(shape(purple,0)); pad(header,18);
        header.addView(text("✚ عيادة دكتورة نجوي",22,Color.WHITE,true));
        header.addView(text("إدارة المواعيد والمرضى والحسابات",12,Color.rgb(235,233,255),false));
        root.addView(header);
        HorizontalScrollView hsv=new HorizontalScrollView(this); hsv.setHorizontalScrollBarEnabled(false);
        nav=row(); nav.setPadding(dp(7),dp(8),dp(7),dp(8));
        for(String name:pages){
            TextView b=text(name,12,name.equals(p)?Color.WHITE:ink,true); b.setGravity(Gravity.CENTER);
            b.setPadding(dp(13),dp(11),dp(13),dp(11)); b.setBackground(shape(name.equals(p)?purple:Color.WHITE,11));
            LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(-2,-2); lp.setMargins(dp(3),0,dp(3),0); nav.addView(b,lp);
            b.setOnClickListener(v->showPage(name));
        }
        hsv.addView(nav); root.addView(hsv);
        ScrollView scroll=new ScrollView(this); body=column(); body.setPadding(dp(14),dp(8),dp(14),dp(24));
        scroll.addView(body); root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
        if(p.equals("الرئيسية")) home();
        else if(p.equals("حجز موعد")) booking(null);
        else if(p.equals("المواعيد")) appointments();
        else if(p.equals("المرضى")) patients();
        else reports();
    }
    void title(String s){ body.addView(text(s,20,ink,true)); }
    LinearLayout card(){
        LinearLayout c=column(); c.setBackground(shape(Color.WHITE,16)); c.setPadding(dp(14),dp(12),dp(14),dp(12));
        LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(-1,-2); lp.setMargins(0,dp(6),0,dp(6)); body.addView(c,lp); return c;
    }
    EditText field(LinearLayout parent,String hint,String value,int type){
        TextView label=text(hint,13,ink,true); parent.addView(label);
        EditText e=new EditText(this); e.setSingleLine(true); e.setTextSize(14); e.setText(value==null?"":value);
        e.setInputType(type); e.setHint(hint); e.setPadding(dp(11),dp(8),dp(11),dp(8));
        e.setBackground(shape(bg,10)); LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(-1,-2); lp.setMargins(0,dp(2),0,dp(10)); parent.addView(e,lp); return e;
    }
    Spinner spinner(LinearLayout parent,String label,String[] options,int selected){
        parent.addView(text(label,13,ink,true)); Spinner s=new Spinner(this);
        ArrayAdapter<String> a=new ArrayAdapter<>(this,android.R.layout.simple_spinner_item,options);
        a.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item); s.setAdapter(a); s.setSelection(selected);
        parent.addView(s); return s;
    }
    String today(){ return new SimpleDateFormat("yyyy-MM-dd",Locale.US).format(new Date()); }
    void home(){
        title("لوحة التحكم");
        Cursor c=db.getReadableDatabase().rawQuery("SELECT COUNT(*), SUM(CASE WHEN date=? AND status!='ملغي' THEN 1 ELSE 0 END), SUM(CASE WHEN paid=1 AND status!='ملغي' THEN fee ELSE 0 END), SUM(CASE WHEN paid=0 AND status!='ملغي' THEN fee ELSE 0 END) FROM appointments",new String[]{today()});
        c.moveToFirst(); int patients=db.countPatients(), today=c.isNull(1)?0:c.getInt(1);
        double paid=c.isNull(2)?0:c.getDouble(2), due=c.isNull(3)?0:c.getDouble(3); c.close();
        stat("إجمالي المرضى",String.valueOf(patients),purple);
        stat("مواعيد اليوم",String.valueOf(today),green);
        stat("تم تحصيله",money(paid)+" ج.م",green);
        stat("مبالغ مستحقة",money(due)+" ج.م",red);
        LinearLayout c1=card(); c1.addView(text("أقرب المواعيد",17,ink,true));
        Cursor a=db.getReadableDatabase().rawQuery("SELECT id,name,date,time,status FROM appointments WHERE status!='ملغي' ORDER BY date,time LIMIT 5",null);
        if(a.getCount()==0)c1.addView(text("لا توجد حجوزات بعد. ابدأ بإضافة موعد جديد.",13,Color.GRAY,false));
        while(a.moveToNext()) c1.addView(text(a.getString(1)+"  •  "+a.getString(2)+" "+a.getString(3)+"\n"+a.getString(4),13,ink,false));
        a.close(); body.addView(button("＋ حجز موعد جديد",purple,()->showPage("حجز موعد")));
    }
    void stat(String label,String value,int color){
        LinearLayout c=card(); c.addView(text(label,13,Color.GRAY,false)); c.addView(text(value,22,color,true));
    }
    void booking(Cursor existing){
        title(existing==null?"حجز موعد جديد":"تعديل الحجز");
        LinearLayout c=card();
        EditText name=field(c,"اسم المريض *",existing==null?"":existing.getString(1),android.text.InputType.TYPE_CLASS_TEXT);
        EditText phone=field(c,"رقم الهاتف *",existing==null?"":existing.getString(2),android.text.InputType.TYPE_CLASS_PHONE);
        EditText date=field(c,"التاريخ (YYYY-MM-DD) *",existing==null?today():existing.getString(3),android.text.InputType.TYPE_CLASS_TEXT);
        EditText time=field(c,"الوقت (مثال 05:30 م) *",existing==null?"05:00 م":existing.getString(4),android.text.InputType.TYPE_CLASS_TEXT);
        EditText service=field(c,"نوع الزيارة",existing==null?"كشف جديد":existing.getString(5),android.text.InputType.TYPE_CLASS_TEXT);
        EditText fee=field(c,"سعر الكشف بالجنيه",existing==null?"200":String.valueOf(existing.getDouble(6)),android.text.InputType.TYPE_CLASS_NUMBER|android.text.InputType.TYPE_NUMBER_FLAG_DECIMAL);
        Spinner pay=spinner(c,"حالة الدفع",new String[]{"غير مدفوع","مدفوع"},existing!=null&&existing.getInt(7)==1?1:0);
        Spinner status=spinner(c,"حالة الموعد",new String[]{"مؤكد","في انتظار التأكيد","ملغي"},existing==null?0:statusIndex(existing.getString(8)));
        EditText notes=field(c,"ملاحظات",existing==null?"":existing.getString(9),android.text.InputType.TYPE_CLASS_TEXT|android.text.InputType.TYPE_TEXT_FLAG_MULTI_LINE);
        int id=existing==null?-1:existing.getInt(0);
        body.addView(button("حفظ البيانات",purple,()->{
            String n=name.getText().toString().trim(), ph=phone.getText().toString().trim(), d=date.getText().toString().trim(), tm=time.getText().toString().trim();
            if(n.isEmpty()||ph.isEmpty()||d.length()!=10||tm.isEmpty()){ toast("من فضلك أكمل الاسم والهاتف والتاريخ والوقت"); return; }
            double amount; try{amount=Double.parseDouble(fee.getText().toString().trim()); if(amount<0)throw new Exception();}catch(Exception ex){toast("أدخل سعر كشف صحيح");return;}
            android.content.ContentValues v=new android.content.ContentValues();
            v.put("name",n);v.put("phone",ph);v.put("date",d);v.put("time",tm);v.put("service",service.getText().toString());
            v.put("fee",amount);v.put("paid",pay.getSelectedItemPosition());v.put("status",status.getSelectedItem().toString());v.put("notes",notes.getText().toString());
            if(id<0) db.getWritableDatabase().insert("appointments",null,v);
            else db.getWritableDatabase().update("appointments",v,"id=?",new String[]{String.valueOf(id)});
            toast("تم حفظ الحجز بنجاح"); showPage("المواعيد");
        }));
    }
    int statusIndex(String s){return s.equals("ملغي")?2:(s.equals("في انتظار التأكيد")?1:0);}
    void appointments(){
        title("إدارة المواعيد");
        LinearLayout c=card(); EditText q=field(c,"بحث بالاسم أو رقم الهاتف","",android.text.InputType.TYPE_CLASS_TEXT);
        body.addView(button("بحث",purple,()->listAppointments(q.getText().toString().trim())));
        listAppointments("");
        q.addTextChangedListener(new android.text.TextWatcher(){public void beforeTextChanged(CharSequence s,int st,int count,int after){} public void onTextChanged(CharSequence s,int st,int before,int count){listAppointments(s.toString());} public void afterTextChanged(android.text.Editable e){}});
    }
    void listAppointments(String query){
        // Rebuild list below the search card.
        while(body.getChildCount()>3) body.removeViewAt(3);
        Cursor c=db.getReadableDatabase().rawQuery("SELECT * FROM appointments WHERE name LIKE ? OR phone LIKE ? ORDER BY date DESC,time DESC",new String[]{"%"+query+"%","%"+query+"%"});
        if(c.getCount()==0){LinearLayout box=card();box.addView(text("لا توجد مواعيد مطابقة.",13,Color.GRAY,false));}
        while(c.moveToNext()){
            final int id=c.getInt(0); LinearLayout box=card();
            box.addView(text(c.getString(1),17,ink,true));
            box.addView(text("📞 "+c.getString(2)+"\n📅 "+c.getString(3)+"   🕒 "+c.getString(4)+"\n"+c.getString(5)+" • "+money(c.getDouble(6))+" جنيه",13,ink,false));
            box.addView(text("الدفع: "+(c.getInt(7)==1?"مدفوع":"غير مدفوع")+"  |  الحالة: "+c.getString(8),13,c.getInt(7)==1?green:red,true));
            LinearLayout actions=row();
            TextView edit=smallButton("تعديل",purple,()->{Cursor x=db.getReadableDatabase().rawQuery("SELECT * FROM appointments WHERE id=?",new String[]{String.valueOf(id)});if(x.moveToFirst()){booking(x);} });
            TextView paid=smallButton("تبديل الدفع",green,()->{Cursor x=db.getReadableDatabase().rawQuery("SELECT paid FROM appointments WHERE id=?",new String[]{String.valueOf(id)});int value=0;if(x.moveToFirst())value=x.getInt(0);x.close();android.content.ContentValues v=new android.content.ContentValues();v.put("paid",value==1?0:1);db.getWritableDatabase().update("appointments",v,"id=?",new String[]{String.valueOf(id)});showPage("المواعيد");});
            TextView cancel=smallButton("إلغاء الموعد",red,()->new AlertDialog.Builder(this).setMessage("هل تريد إلغاء هذا الموعد؟").setNegativeButton("رجوع",null).setPositiveButton("إلغاء", (d,w)->{android.content.ContentValues v=new android.content.ContentValues();v.put("status","ملغي");db.getWritableDatabase().update("appointments",v,"id=?",new String[]{String.valueOf(id)});showPage("المواعيد");}).show());
            actions.addView(edit);actions.addView(paid);actions.addView(cancel);box.addView(actions);
        } c.close();
    }
    void patients(){
        title("ملفات المرضى");
        LinearLayout c=card(); EditText q=field(c,"بحث بالاسم أو رقم الهاتف","",android.text.InputType.TYPE_CLASS_TEXT);
        body.addView(button("بحث",purple,()->listPatients(q.getText().toString())));
        listPatients(""); q.addTextChangedListener(new android.text.TextWatcher(){public void beforeTextChanged(CharSequence s,int st,int count,int after){} public void onTextChanged(CharSequence s,int st,int before,int count){listPatients(s.toString());} public void afterTextChanged(android.text.Editable e){}});
    }
    void listPatients(String q){
        while(body.getChildCount()>3)body.removeViewAt(3);
        Cursor c=db.getReadableDatabase().rawQuery("SELECT name,phone,COUNT(*),SUM(fee) FROM appointments WHERE name LIKE ? OR phone LIKE ? GROUP BY phone,name ORDER BY name",new String[]{"%"+q+"%","%"+q+"%"});
        if(c.getCount()==0){LinearLayout box=card();box.addView(text("ستظهر بيانات المرضى بعد إضافة أول حجز.",13,Color.GRAY,false));}
        while(c.moveToNext()){LinearLayout box=card();box.addView(text(c.getString(0),17,ink,true));box.addView(text("الهاتف: "+c.getString(1)+"\nعدد الزيارات: "+c.getInt(2)+"\nإجمالي قيمة الحجوزات: "+money(c.getDouble(3))+" جنيه",13,ink,false));}
        c.close();
    }
    void reports(){
        title("الحسابات والتقارير"); Cursor c=db.getReadableDatabase().rawQuery("SELECT COUNT(*),SUM(fee),SUM(CASE WHEN paid=1 THEN fee ELSE 0 END),SUM(CASE WHEN paid=0 AND status!='ملغي' THEN fee ELSE 0 END) FROM appointments WHERE status!='ملغي'",null);
        c.moveToFirst(); stat("عدد الحجوزات",String.valueOf(c.getInt(0)),purple);stat("إجمالي قيمة الحجوزات",money(c.isNull(1)?0:c.getDouble(1))+" ج.م",ink);stat("المبالغ المحصلة",money(c.isNull(2)?0:c.getDouble(2))+" ج.م",green);stat("المبالغ المستحقة",money(c.isNull(3)?0:c.getDouble(3))+" ج.م",red);c.close();
        LinearLayout box=card();box.addView(text("تنبيه",16,ink,true));box.addView(text("البيانات محفوظة على هذا الهاتف فقط. استخدم النسخ الاحتياطي بانتظام، ولا تحذف التطبيق قبل حفظ بياناتك.",13,Color.GRAY,false));
    }
    String money(double d){return String.format(Locale.US,"%.2f",d);}
    void toast(String s){Toast.makeText(this,s,Toast.LENGTH_LONG).show();}
    static class DB extends SQLiteOpenHelper{
        DB(Context c){super(c,"najwa_clinic.db",null,1);}
        public void onCreate(SQLiteDatabase d){d.execSQL("CREATE TABLE appointments (id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,phone TEXT NOT NULL,date TEXT NOT NULL,time TEXT NOT NULL,service TEXT,fee REAL NOT NULL DEFAULT 0,paid INTEGER NOT NULL DEFAULT 0,status TEXT NOT NULL DEFAULT 'مؤكد',notes TEXT)");}
        public void onUpgrade(SQLiteDatabase d,int oldV,int newV){}
        int countPatients(){Cursor c=getReadableDatabase().rawQuery("SELECT COUNT(DISTINCT phone) FROM appointments",null);c.moveToFirst();int n=c.getInt(0);c.close();return n;}
    }
}
'''
}
for path, content in files.items():
    full = os.path.join(base, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", encoding="utf-8") as f:
        f.write(content)
zip_path = "/mnt/data/ClinicNajwaAndroid_AIDE_Project.zip"
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
    for rootdir, dirs, filenames in os.walk(base):
        for fn in filenames:
            full = os.path.join(rootdir, fn)
            z.write(full, os.path.relpath(full, base))
print("Created project:", zip_path)
print("Files:", len(files), "ZIP bytes:", os.path.getsize(zip_path))