class TopsController < ApplicationController
	def top #昼会を始めるというボタンがあるページに行くアクション
	end

	def shift_print
	end

	def qa_make
		if !Date.today.friday?
			days = Day.where(shift_day: Date.today) #qaは1日に１回しか実行されない
			if days == []
				# とりあえずここでqa決める
				# まず1時からと22時までの人の配列作る
				today_staff = Shift.where(date: Date.today, group_id: "wc").or(Shift.where(date: Date.today, group_id: "wcp"))
				todaystaff_array = today_staff.pluck(:air_staff_id) #pluckメソッドで指定したカラムだけを配列として保存している
				todaystart_array = today_staff.pluck(:start)
				todayend_array = today_staff.pluck(:end)
				todayshift = []
				# 2次元配列初期化
				today_staff.count.times do |i|
					s = 0
					todayshift.count.times do |j|
						if todayshift[j] == nil
							next
						end
						if todayshift[j][0] == todaystaff_array[i] && todayshift[j][2] == todaystart_array[i]
							todayshift[j][2] = todayend_array[i]
							s = 1
						end 
					end
					if s == 0
						todayshift[i] = [todaystaff_array[i], todaystart_array[i], todayend_array[i]]
					end
				end
				todayshift = todayshift.compact # nilなくす
				# 昨日のqaリーダーを省く
				b = []
				qayesterday = Day.where(shift_day: Date.yesterday)
				qayesterday = qayesterday.pluck(:qastaff_id)
				qayesterday.count.times do |i|
					todayshift.count.times do |j|
						if qayesterday[i] == todayshift[j][0]
							b.push(j)
						end
					end
				end
				b.count.times do |i|
					todayshift.delete_at(b[i])
				end
				# 研修省く
				b = []
				todaytrain = TrainShift.where(date: Date.today)
				todaytrain = todaytrain.pluck(:staff_id)
				todaytrain = Staff.where(id: todaytrain)
				todaytrain = todaytrain.pluck(:air_staff_id)
				todaytrain.count.times do |i|
					todayshift.count.times do |j|
						if todaytrain[i] == todayshift[j][0]
							b.push(j)
						end
					end
				end
				b.count.times do |i|
					todayshift.delete_at(b[i])
				end

				c = [1,1,1,1,1]
				c[rand(0..4)] = 0
				c[rand(0..4)] = 0

				c = c.sample # 0 or 1

				allday = []
				halfday = []
				justhalfday = [] # 13時からか22時まで

				todayshift.count.times do |i|
					if todayshift[i][1].strftime("%Y-%m-%d %H:%M:%S") == "#{Date.today} 13:00:00" && todayshift[i][2].strftime("%Y-%m-%d %H:%M:%S") == "#{Date.today} 22:00:00"
						allday.push(todayshift[i])
					elsif todayshift[i][1].strftime("%Y-%m-%d %H:%M:%S") == "#{Date.today} 13:00:00" || todayshift[i][2].strftime("%Y-%m-%d %H:%M:%S") == "#{Date.today} 22:00:00"
						justhalfday.push(todayshift[i])
					end
				end

				if allday == []
					c = 1
				elsif justhalfday == []
					c = 0
				end

				qa = []
				if c == 0 #1日の人
					qa.push(allday.sample)
					day = Day.create(shift_day: Date.today, qastaff_id: qa[0][0], start: qa[0][1], end: qa[0][2])
				else
					# まず一人選ぶ そっからもう一人選ぶけどhalfの人優先に選ぶ
					f = justhalfday.sample
					justhalfday.delete(f)
					qa.push(f)

					g = []
					if f[1].hour == 13
						justhalfday.count.times do |i|
							if justhalfday[i][2].hour == 22 && justhalfday[i][1] < f[2]
								g.push(justhalfday[i])
							end
						end
					else
						justhalfday.count.times do |i|
							if justhalfday[i][1].hour == 13 && justhalfday[i][2] > f[1]
								g.push(justhalfday[i])
							end
						end
					end
					if g == []
						if allday == []
							all = Shift.find_by(start: "#{Date.today} 13:00:00", end: "#{Date.today} 22:00:00")
							# ここランダムにすると良い
							qa.push([all.air_staff_id, all.start, all.end])
						else
							qa.push(allday.sample)
						end
					else
						qa.push(g.sample)
					end
					if qa[0][1].hour == 13
						qa[1][1] = qa[0][2]
					else
						qa[1][2] = qa[0][1]
					end

					qa.count.times do |i|
						day = Day.create(shift_day: Date.today, qastaff_id: qa[i][0], start: qa[i][1], end: qa[i][2])
					end
				end
			end
		end	
		@days = Day.where(shift_day: Date.today)
	end

	def rest_shift_change(num, bad_time) #badtimeをもとに、restテーブルと配列numの値を更新する
		if bad_time[0] != [] #教室のメンターが二人以下の場合
			bad_time[0].each do |time|

			end
		end
		if bad_time[1] != [] #プロメンターがーない場合
			bad_time[1].each do |time|
			end
		end
		return num
	end

	def rest_shift_make
		# これで教室にいるメンターの人数をカウントできる[時間,[wcメンター,wcpメンター]]という3重配列
		num = [] #配列の初期化
		13.step(21.5, 0.5) do |n|
			num.push([n,[0,0]])
		end

		Shift.where(date: Date.today).each do |shift| #何人シフトに入っているかの配列を作成する（休憩は考慮しない）
			work_start = shift.start.hour + shift.start.min / 60.0
			work_end = shift.end.hour + shift.end.min / 60.0
			13.step(21.5, 0.5) do |n| #１３から２２まで0.5ずつ順番に足していく
				if work_start <= n && n < work_end #nから先30分の間に働いている人（22時は0になる）
					if shift.group_id == "wc"
						num[(n - 13)*2][1][0] += 1
					elsif shift.group_id == "wcp"
						num[(n - 13)*2][1][1] += 1
					end
				end
			end
		end

		#もし実行が２回目以上の場合、今日の休憩シフトをすべて削除
		if Rest.all != []
			if Rest.all.last.day == Date.today #配列に何も入っていないと、Rest.all.last.dayがno_methodとなる
				Rest.where(day: Date.today).destroy_all
			end
		end

		rest_60_start = 17
		TodayWork.where('working_hour >= ?',6).each do |today_shift| #WCP研修やBCなどがシフトの中に含まれている人はrest_startnullとなる
			rest_new = Rest.new
			rest_new.staff_id = today_shift.staff.id
			rest_new.day = Date.today
			if today_shift.working_hour == 9
				rest_new.rest_time = 60
			elsif today_shift.working_hour >= 6
				rest_new.rest_time = 30
			end

			today_shift.staff.shifts.where(date: Date.today).each do |shift| #要検討
				if shift.group_id == "wcp研修"
					rest_new.rest_start = 0 #0を入れてもdatetime型に変換されず、nilになる
					rest_new.group_id = 3546
				elsif shift.group_id == "BC"
					rest_new.rest_start = 0
					rest_new.group_id = 8375
				elsif shift.group_id == "プロダクト"
					rest_new.rest_start = 0
					rest_new.group_id = 3545
				elsif shift.group_id == "研修"
					rest_new.rest_start = 0
					rest_new.group_id = 7292
				end

				if rest_new.group_id == nil
					if shift.group_id == "wc"
						rest_new.group_id = 3385
					elsif shift.group_id == "wcp"
						rest_new.group_id = 3386
					end
				end
			end

			if rest_new.group_id == "wc" || rest_new.group_id == "wcp"
				if rest_new.rest_time == 30
					rest_new.rest_start = today_shift.start + today_shift.working_hour * 3600 / 2
				elsif rest_new.rest_time == 60
					today = Date.today
					if rest_60_start <= 18
						rest_new.rest_start = DateTime.new(today.year,today.month,today.day,rest_60_start,0,0,'+09:00')
					else
						rest_new.rest_start = DateTime.new(today.year,today.month,today.day,rest_60_start-2,30,0,'+09:00')
					end
					rest_60_start += 1
				end

				if rest_new.rest_start.to_i % 1800 != 0 #休憩シフトが30分単位にならなかった場合
					rest_new.rest_start -= rest_new.rest_start.to_i % 1800
				end

				rest_start_int = rest_new.rest_start.hour + rest_new.rest_start.min / 60.0 #これは30分単位
				if rest_new.rest_time == 60
					if rest_new.group_id == "wc"
						num[(rest_start_int - 13) * 2][1][0] -= 1
						num[(rest_start_int - 13) * 2 + 1][1][0] -= 1
					elsif rest_new.group_id == "wcp"
						num[(rest_start_int - 13) * 2][1][1] -= 1
						num[(rest_start_int - 13) * 2][1][1] -= 1
					end
				elsif rest_new.rest_time == 30
					if rest_new.group_id == "wc"
						num[(rest_start_int - 13) * 2][1][0] -= 1
					elsif rest_new.group_id == "wcp"
						num[(rest_start_int - 13) * 2][1][1] -= 1
					end
				end
			end
			rest_new.save
		end

		count = 0
		while true do
			count += 1
			# よくないパターン
			# １、合計が３人以下
			# ２、WCPメンターがいない
			bad_time = [[],[]] #よくない時間を格納する配列
			num.each do |time|
				# time[1][0] #ある時間のwcのメンターの人数
				# time[1][1] #ある時間のwcpメンターの人数
				if time[1][0] + time[1][1] <= 2
					bad_time[0].push(time[0])
				elsif time[1][1] == 0
					bad_time[1].push(time[0])
				end
			end
			if bad_time == [[],[]] || count > 5 #bad_timeがなかった場合または５回以上チェックした場合は休憩シフトを確定する
				break
			end
			binding.pry #ここで止まるということは休憩シフトの組み方がよくないということ
			num = rest_shift_change(num,bad_time)
		end
	end

	def post_slack #スラックで送信する
	    notifier = Slack::Notifier.new(
				ENV["SLACK_POST_URL"]
		) #取得したslackのWebhook URL
		# 全員の情報
		# notifier.ping(staffs)

		# range = Date.today.beginning_of_day..Date.today.end_of_day
		today_shifts = Shift.where(date: Date.today)

		today_staffs = []
		today_shifts.order("group_id").each do |today_shift|
			today_staff = today_shift.staff
			today_staffs.push(today_shift.group_id)
			today_staffs.push(today_staff.name + " ")
			today_staffs.push(today_shift.start.strftime("%H:%M")+"~"+today_shift.end.strftime("%H:%M"))
			today_staffs.push("\n")
		end

		today_rests = []
		rests = Rest.where(day: Date.today)
		rests.order("group_id").each do |rest|
			today_rests.push(rest.group_id)
			today_rests.push(rest.staff.name)
			if rest.rest_time != 0
				today_rests.push(rest.rest_start.strftime("%H:%M")+"~"+(rest.rest_start + rest.rest_time*60).strftime("%H:%M"))
			elsif rest.rest_time == 0
				today_rests.push("研修中に取ってください")
			end
			today_rests.push("\n")
		end

		today_trainings = []
		trainings = TrainShift.where(date: Date.today)
		if trainings == []
			today_trainings.push("今日は新人研修の予定はありません")
		else
			trainings.each do |training|
				today_trainings.push(training.staff.name)
				today_trainings.push(training.start.strftime("%H:%M")+"~"+training.end.strftime("%H:%M"))
			end
		end

		today_qa = []
		Day.where(shift_day: Date.today).order("start").each do |qa|
			today_qa.push(Staff.find_by(air_staff_id: qa.qastaff_id).name)
			today_qa.push(qa.start.strftime("%H:%M") + "~" + qa.end.strftime("%H:%M"))
			today_qa.push("\n")
		end

		today_trainings = today_trainings.join()
		today_staffs = today_staffs.join()
		today_rests = today_rests.join()
		today_qa = today_qa.join()

		today = Date.today.strftime("%m/%d")
		# notifier.ping("<!here>")
		notifier.ping("【今日(#{today})のシフト】\n" + today_staffs + "\n")
		notifier.ping("【休憩シフト】\n" + today_rests)
		notifier.ping("【新人研修予定】\n" + today_trainings + "\n")
		notifier.ping("【QAリーダー】\n" + today_qa + "\n")
		notifier.ping("教室の様子見て人数的に余裕がありそうなら早めに休憩取って下さい。＊漏れ＊ 、 ＊抜け＊ 、 ＊足りない＊ 、 ＊入ってない＊ 、 ＊ブッキング＊ などありましたら下記のURLからアクセスして訂正ください。訂正した分が自動的にこのチャンネルに投稿されます。本日もよろしくお願いいたします! ")
		notifier.ping("http://localhost:3000/main")
	end

	def get_train_shift #google driveのスプレッドシートから値を取って来ている
	 	#この３つの値が必要、ここでは環境変数を設定するためにconfigというgemを使っている。
		client_id     = ENV["GOOGLE_DRIVE_CLIENT_ID"]
		client_secret = ENV["GOOGLE_DRIVE_CLIENT_SECRET"]
		refresh_token = ENV["GOOGLE_DRIVE_REFRESH_TOKEN"]

		#    #ここからデータを取りに行っている
	    client = OAuth2::Client.new(client_id,client_secret,site: "https://accounts.google.com",token_url: "/o/oauth2/token",authorize_url: "/o/oauth2/auth")
	    auth_token = OAuth2::AccessToken.from_hash(client,{:refresh_token => refresh_token, :expires_at => 3600})
	    auth_token = auth_token.refresh!
	    session = GoogleDrive.login_with_oauth(auth_token.token)

	  # wsにスプレッドシートのデータが入っている。session.spreadsheet_by_keyはスプレッドシートを開いたときのURLの一部
	    ws = session.spreadsheet_by_key("1vvvwo43INRE8orVAjD3PZOFlTzuvIAWWyE9RrXB4HgI").worksheets[0]
	    day = Date.today

	    if TrainShift.all != []
		    if TrainShift.all.last.date == Date.today
				TrainShift.where(date: Date.today).destroy_all
			end
		end

	    ((ws.num_rows-3)/4).times do |row|
	    	# puts ws[(row+1)*4, 1]
	    	(8..ws.num_cols).each do |col|
	    	 	if Date.today == ws[(row+1)*4, col].to_date && (ws[3, col][0] == "第" || ws[3, col][0] == "O")
	    	 		train_shift = TrainShift.new

	    	 		#スタッフが見つけれなかった場合を書かないとエラーになる（修正検討）
	    	 		train_shift.staff_id = Staff.find_by(name: ws[((row+1)*4)+1, col]).id
	    	 		train_shift.start = DateTime.new(day.year.to_i, day.month.to_i, day.day.to_i, ws[((row+1)*4)+2, col][0, 2].to_i, ws[((row+1)*4)+2, col][3, 2].to_i,0,'+09:00')
	    	 		train_shift.end = DateTime.new(day.year.to_i, day.month.to_i, day.day.to_i, ws[((row+1)*4)+3, col][0, 2].to_i, ws[((row+1)*4)+3, col][3, 2].to_i,0,'+09:00')
	    	 		if ws[3, col][0] == "第"
	    	 			train_shift.which = "training"
	    	 		else
	    	 			train_shift.which = "OJT"
	    	 		end
	    	 		train_shift.date = Date.today
	    	 		train_shift.save
	    		end
	    	end
	    end
	end

	def scrape_main
		agent = Mechanize.new

		#ここをデプロイする時に変更する必要がある
		agent.user_agent_alias = 'Mac Safari 4'
		agent.get('https://connect.airregi.jp/login?client_id=SFT&redirect_uri=https%3A%2F%2Fconnect.airregi.jp%2Foauth%2Fauthorize%3Fclient_id%3DSFT%26redirect_uri%3Dhttps%253A%252F%252Fairshift.jp%252Fsft%252Fcallback%26response_type%3Dcode') do |page|

		  	mypage = page.form_with(id: 'command') do |form|
		    # ログインに必要な入力項目を設定していく
		    # formオブジェクトが持っている変数名は入力項目(inputタグ)のname属性
		    	form.username = ENV["AIR_SHIFT_USERNAME"]
		    	form.password = ENV["AIR_SHIFT_PASSWORD"]

		  	end.submit

		  	#HTMLにしている
		  	doc = Nokogiri::HTML(mypage.content.toutf8)

		  	#jsonのデータとして情報をとってきている
			doc_j = doc.xpath("//script")[3]["data-json"]

			# 何回もログインしなくていいようにデータを保存する
			# doc_j = Datum.find(1).doc
			#jsonをhashに変換
			hash = JSON.parse doc_j
			# binding.pry
			#これがスタッフの情報
			staffs = hash["app"]["staffList"]["staff"]
			shifts = hash["app"]["monthlyshift"]["shift"]["shifts"]

			if staffs.count != Staff.all.count #もし既存スタッフの人数とスクレイピングして得たスタッフの人数が違うならば、保存し直す。
				Staff.destroy_all #全員削除する
				staffs.each do |staff|
					staff_new = Staff.new
					staff_new.air_staff_id = staff["id"]
					staff_new.name = staff["name"]["family"] + staff["name"]["first"]
					#一度保存したら保存しなくて良い
					staff_new.save
				end
			end

			if Shift.all != [] && Shift.all.last.date == Date.today #1日に２回以上実行したならば、下の２つを削除する
				Shift.where(date: Date.today).destroy_all
			end
			TodayWork.all.destroy_all #これは毎日削除する
			shifts.each do |shift| #このループはshiftとtoday_workの作成
				#時間が入っていない場合がある
				#はじめに休む人の時間を設定
				if shift["workTime"]["start"] != nil
					#これによって日付をとってきている
					year = shift["date"][0,4].to_i
					month = shift["date"][4,2].to_i
					day = shift["date"][6,2].to_i

					date = Date.new(year,month,day)
					#その日の分のシフトデータだけを保存するようにする
					if date.today? && shift["groupId"].to_i != 0
						# 休憩テーブルも作成する
						shift_new = Shift.new

						# 始まりの時間
						start_hour = shift["workTime"]["text"][-13,2].to_i
						start_minute = shift["workTime"]["text"][-10,2].to_i

						# 終わりの時間
						end_hour = shift["workTime"]["text"][-5,2].to_i
						end_minute = shift["workTime"]["text"][-2,2].to_i

						shift_new.start = DateTime.new(year,month,day,start_hour,start_minute,0,'+09:00')
						shift_new.end = DateTime.new(year,month,day,end_hour,end_minute,0,'+09:00')
						shift_new.air_staff_id = shift["staffId"]

						staff = Staff.find_by(air_staff_id: shift["staffId"])

						shift_new.staff_id = staff.id
						shift_new.group_id = shift["groupId"].to_i
						shift_new.date = Date.today
						shift_new.save

						working_hour = (shift_new.end - shift_new.start)/3600

						# その日のシフトの始まりと終わりを記録する
						if staff.today_work == nil
							today_work = TodayWork.new
							today_work.working_hour += working_hour
							today_work.staff_id = staff.id
							today_work.start = shift_new.start
							today_work.day = Date.today
							today_work.end = shift_new.end
						elsif staff.today_work.start > shift_new.start
							today_work = staff.today_work
							today_work.start = shift_new.start
						elsif staff.today_work.end < shift_new.end
							today_work = staff.today_work
							today_work.end = shift_new.end
						end
						today_work.save
					end
				end
			end
		end
	end

	def scrape
		scrape_main

		get_train_shift
	    
		rest_shift_make #休憩シフトを決める関数を呼び出す

		# QAリーダを決める関数
		qa_make
      
		# スラックに投稿する関数を呼び出す
		# post_slack

	    shift_print
	end

	def main
		@staffs = Staff.all

		#これで今日のシフトがとれる
		@today_shifts = Shift.where(date: Date.today)

		#今日の研修を持ってくる
		@today_trains = TrainShift.where(date: Date.today)

		#今日の休憩シフトを持ってくる
		@rests = Rest.where(day: Date.today)

		@days = Day.where(shift_day: Date.today)
	end

	def edit_rest
		@rest = Rest.find(params[:id])
	end

	def rest_update
		rest = Rest.find(params[:id])
		before_start = rest.rest_start
		before_end = rest.rest_start + rest.rest_time * 60
		rest.update(rest_params)
		notifier = Slack::Notifier.new(
				"https://hooks.slack.com/services/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"
		)
		message = rest.staff.name + "さんの休憩時間を" + before_start.strftime("%H:%M") + "~" + before_end.strftime("%H:%M") + "から" + rest.rest_start.strftime("%H:%M") + "~" + (rest.rest_start + rest.rest_time * 60).strftime("%H:%M") + "に変更しました。ご確認お願いします。"


		notifier.ping(message)
		redirect_to main_path
	end

	def edit_qa
		@qa = Day.where(shift_day: Date.today)
		@staff = Shift.where(date: Date.today)
	end

	def update_qa
		qa_params.each do |f|
			day = Day.find(f[0].to_i)
			day.update(start: "#{Date.today} #{f[1]["start(4i)"]}:#{f[1]["start(5i)"]}:00", end: "#{Date.today} #{f[1]['end(4i)']}:#{f[1]['end(5i)']}:00")
		end	
	end

	def delete_qa
		Day.find(params[:id]).destroy
		redirect_to qa_edit_path
	end

	def add_qa
		puts add_qa_staff
		day = Day.new()
		day.shift_day = Date.today
		day.qastaff_id = add_qa_staff["0"]
		day.start = "#{Date.today} #{add_qa_staff["1"]}:#{add_qa_staff["2"]}:00"
		day.end = "#{Date.today} #{add_qa_staff["3"]}:#{add_qa_staff["4"]}:00"
		day.save
		redirect_to qa_edit_path
	end

	private
	def rest_params
		params.require(:rest).permit(:rest_start, :rest_time)
	end

	def qa_params
		params.require(:qa)
	end
	def add_qa_staff
		params.require(:qa).permit("0", "1", "2", "3", "4")
	end
end