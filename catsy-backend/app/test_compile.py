import py_compile
try:
    py_compile.compile('/mnt/datadrive/Project/Catsy-Final/catsy-backend/app/repositories/supabase_repo.py', doraise=True)
except Exception as e:
    print(e)
