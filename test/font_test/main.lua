function love.draw()
   love.graphics.setBackgroundColor(0,0,0,1)
   love.graphics.setColor(1,1,1,1)
   love.graphics.print([[$1 $2 $3 $4 $5 $6 $7 $8 $9 $0
£1 £2 £3 £4 £5 £6 £7 £8 £9 £0
€1 €2 €3 €4 €5 €6 €7 €8 €9 €0
฿1 ฿2 ฿3 ฿4 ฿5 ฿6 ฿7 ฿8 ฿9 ฿0
1¢ 2¢ 3¢ 4¢ 5¢ 6¢ 7¢ 8¢ 9¢ 0¢
1/2 2/3 4/5 6/7 8/9
111 222 333 444 555 666 777 888 999 000
1¹ 1² 1³ 2¹ 2² 2³ 3¹ 3² 3³ 4¹ 4² 4³ 5¹ 5² 5³ 6¹ 6² 6³ 7¹ 7² 7³ 8¹ 8² 8³ 9¹ 9² 9³
1% 2% 3% 4% 5% 6% 7% 8% 9% 10%
⅕ ¼ ⅓ ½ ⅔ ¾
Av Aw Ay Az Fa Fe Fi Fo Fu Kv Kw Ky Pa Pe Po Ta Te
Ti To Tr Ts Tu Ty Va Ve Vo Vr Vu Vy Wa We Wr Wv Wy
AC AT AVA AWA AYA AV AW AY AZ CT CYC FA FE FO KV KW KY
LO LV LY NG OD PA PA PE PO TA TA TE TI TO TR TS TU TY
UA VA VA VE VO VR VU VY WA WO WA WE WR WV WY YS]],5,5)
   -- if true then
   --    io.write(love.graphics._getScreen():newImageData():encode("png"):getString())
   --    os.exit(0)
   -- end
end
