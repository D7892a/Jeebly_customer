رابطة الفرق الشعبية في المنصورية — نظام Supabase

1. تم تنفيذ قاعدة البيانات على مشروع jeebly-nasiriyah بالفعل؛ لا تحتاج لتشغيل database.sql مرة ثانية.
2. ارفع محتويات هذا المجلد كاملة إلى استضافة HTTPS مثل Netlify أو GitHub Pages. ملف index.html للجمهور و admin.html للإدارة.
3. لإنشاء حساب الإدارة: Supabase > Authentication > Users > Add user (بريد وكلمة مرور).
4. انسخ بريد المدير إلى استعلام SQL التالي في SQL Editor (بدل YOUR_ADMIN_EMAIL):
insert into public.mans_admins(user_id)
select id from auth.users where email='YOUR_ADMIN_EMAIL'
on conflict do nothing;
5. افتح admin.html وسجل دخول المدير. أضف الفرق ثم البطولات وحدد المشاركين ثم أضف المباريات.
6. لتفعيل التحديث اللحظي: Database > Publications > supabase_realtime وأضف الجداول mans_teams وmans_tournaments وmans_tournament_teams وmans_matches. بدون هذه الخطوة تظهر التغييرات بعد إعادة تحميل صفحة الجمهور.
7. مفتاح config.js مفتاح publishable عام ومسموح داخل المتصفح، أما service_role فلا تضعه في الملفات أبداً.
8. البيانات لا تحتوي على أمثلة وهمية؛ أضف أسماء وشعارات الفرق الحقيقية من الإدارة.
9. حذف فريق لديه مباريات مرتبط بها ممنوع لحماية سجل النتائج. احذف أو عدّل المباريات المرتبطة أولاً.
10. التطبيق يحتاج اتصال إنترنت لاستدعاء Supabase، ويفضل تشغيله من HTTPS بدلاً من file://.
