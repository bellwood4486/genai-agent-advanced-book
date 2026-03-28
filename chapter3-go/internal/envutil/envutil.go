package envutil

import (
	"fmt"
	"os"

	"github.com/joho/godotenv"
)

// Load は .env ファイルを読み込む。ファイルが存在しない場合は無視する。
func Load() {
	_ = godotenv.Load()
}

// MustGetenv は環境変数を取得する。未設定の場合はパニックする。
func MustGetenv(key string) string {
	v := os.Getenv(key)
	if v == "" {
		panic(fmt.Sprintf("環境変数 %s が設定されていません", key))
	}
	return v
}
