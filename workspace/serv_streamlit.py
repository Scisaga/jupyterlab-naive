import streamlit as st

st.set_page_config(page_title="JupyterLab Demo", layout="wide")
st.title("🧪 Streamlit Demo in JupyterLab")

text = st.text_input("输入内容：")
if text:
    st.success(f"你输入了：{text}")