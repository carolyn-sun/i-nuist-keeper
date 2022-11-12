//V 0.3.2 26d643f

import net.http
import os
import time

struct Info {
mut:
	acc string
	pwd string
	ip string
	isp struct {
	mut:
		name string
		no string
	}
}

fn main() {
	println('本项目地址: https://github.com/carolyn-sun/i-nuist-keeper')
	if scan()! != true {
		mut info := Info {
			acc: os.input('请键入用户名: ')
			pwd: os.input('请键入密码: ')
			isp: struct {
				no: os.input('请键入运营商序号(移动/电信/联通对应2/3/4): ')
				}
			}
		info.isp.name = no2name(info.isp.no)
		if login(info)! {
			println('登录成功, 用户信息已经保存')
		} 
	}
	println('连接成功, 程序将在此每6秒检测一次网络连接性, 你可以将其最小化但请勿关闭')
	println('前往本项目地址了解设置为开机自启的办法')
	for {
		if check()! != true {
			println('网络连接丢失, 正在尝试重新登录使你在线')
		start_check()!
			if check()! {
				println('重连成功')
			}
		}
		time.sleep(6000 * time.millisecond)
	}
}

fn get_ip() !string {
	res := http.get('http://10.255.255.34/api/v1/ip') or {
		println('Error1: 无法连接到i-NUIST: 检查你的无线网络设置')
	}.body
	if res.all_after('\"code\":').all_before(',\"data\"').contains_any('200') {
		return res.all_after('\"data\":\"').all_before('\"}')
	}
	return 'NULL'
}

fn login(info Info) !bool {
	ip := get_ip()!
	if ip != 'NULL' {
		payload := '{\"username\":\"$info.acc\",\"password\":\"$info.pwd\",\"channel\":\"$info.isp.no\",' 
		+ '\"ifautologin\":\"1\",\"pagesign\":\"secondauth\",\"usripadd\":\"$ip\"}'
		res := http.post('http://10.255.255.34/api/v1/login/', payload) or {
			return false
		}.body
		if res.all_after('\"message\": ').all_before_last(',').contains_any('ok') && check()! {
			raw := '{\"username\":\"$info.acc\",\"password\":\"$info.pwd\",\"channel\":\"$info.isp.no\",' 
			+ '\"ifautologin\":\"1\",\"pagesign\":\"secondauth\",\"usripadd\":\"'
			write(raw) or {
				println('Error3: 文件写入错误: 检查AppData目录的权限')
				return false
			}
			return true
		} else {
			println('Error2: 暂时无法认证, 可能是因为故障, 或欠费/帐号信息有误')
		}
	}
	return false
}


fn check() !bool {
	resp := http.get('http://dns.alidns.com/resolve?name=taobao.com.&type=1')!
	res := resp.body
	if res.contains_any('\"Status\":0') && res.contains_any('TTL') {
		return true
	}
	return false
}

fn write(raw string) !bool {
	url := os.config_dir()! + '\\i-nuist-keeper-cache.dat'
	os.write_file(url, raw) or {
		println('Error3: 文件写入错误: 检查AppData目录的权限')
		return false
	}
	println("帐号信息已经保存在本地, 位置为$url")
	return true
}

fn read() !string {
	url := os.config_dir()! + '\\i-nuist-keeper-cache.dat'
	if os.exists(url) {
		return os.read_file(url) or {
			'NULL'
		}
	}
	return 'NULL'
}

fn start_check() !bool {
	raw := read()!
	if raw != 'NULL' {
		ip := get_ip()!
		payload := raw + '\"$ip\"}'
		for (check()! == false) {
			simple_post(payload)
		}
		return true
	}
	return false
}

fn no2name(no string) string {
	return match no {
		'2' {'中国移动'}
		'3' {'中国电信'}
		'4' {'中国联通'}
		else {'未定义'}
	}
}

fn scan() !bool {
	url := os.config_dir()! + '\\i-nuist-keeper-cache.dat'
	if start_check()! {
		println('检测到保存在本地的帐号, 正在尝试使你登录')
		println('如果要使用别的帐号登录, 请在关闭程序后删除$url')
		return true
	}
	return false
}

fn simple_post(payload string) http.Response {
	return http.post('http://10.255.255.34/api/v1/login/', payload) or {
		simple_post(payload)
	}
}
